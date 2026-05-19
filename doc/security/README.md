# Auditoria de segurança — IDOR

Diretório de artefatos da Task 2 (maio/2026): auditoria e correção de autorização no Fab-manager Firjan.

## Rodadas

| Rodada | Branch | Status | Entrega |
|---|---|---|---|
| v1 | `feat/firjan-security-idor` → squash em `feat/firjan-report` (`f8f3d1675`) | ✅ Em produção | Fix `UserPolicy#show?` + baseline IDOR + analisador estático |
| v2 | `feat/firjan-security-idor-v2` | 🚧 Em revisão | Patch upstream `fa5489ae6` adaptado + `groups` |
| v3 | `feat/firjan-security-idor-v2` (continuação) | 🚧 Em revisão | Achados do pentest browser-driven 2026-05-17: IDOR em show actions + Getnet authz + XSS hardening |
| v4 | `feat/firjan-security-idor-v2` (continuação) | 🚧 Em revisão | Respostas do Claupper às Q1/Q2/Q3 de `resposta-claupper-2026-05-17.md` — search mínimo 3 chars, Devise Timeoutable + session fingerprint, e documentação de risco aceito |

## Override operacional do session fingerprint

A checagem de `validate_session_fingerprint` (Q2c, em `ApplicationController`) pode ser **degradada** para UA-only via env var sem novo deploy de código:

```
SKIP_SESSION_FINGERPRINT=true
```

**Quando usar:** se em produção observarmos 401 em massa logo após o deploy da v4 e a causa raiz for o `request.remote_ip` oscilando atrás do proxy do Azure App Service (cada request volta de um IP diferente do load balancer, então o fingerprint nunca bate). Ligar a flag desconsidera o componente IP mas mantém o vínculo da sessão ao User-Agent.

**Comportamento da flag:**
- **OFF (padrão):** fingerprint = `SHA256(IP/24 + UA)`. Cookie replicado em qualquer outra rede ou outro UA é rejeitado.
- **ON (rollback):** fingerprint = `SHA256(UA)`. Cookie replicado de outra rede mas no mesmo navegador passa; replay via `curl` (UA diferente) continua sendo rejeitado.

A sessão usa chave distinta por regime (`:_session_fp` vs `:_session_fp_ua`), então **virar a flag em qualquer direção não desloga ninguém** — o próximo request semeia a chave do novo regime e segue normal.

**O que continua valendo com a flag ON:**
- `Devise.timeout_in = 1.hour` (Q2a — inatividade força re-login).
- Session cookie absoluto de 8 horas (Q2b — `expire_after` em `config/initializers/session_store.rb`).
- Cookie ainda `HttpOnly + Secure + SameSite=Lax`.
- Detecção de UA mismatch (curl, bot, ferramenta de pentest).

**O que para de valer:** cookie roubado e usado no MESMO navegador (mesmo UA string) de outra rede passa dentro da janela de 8h. Por isso a flag é **operacional**, não permanente — a saída correta é configurar `config.action_dispatch.trusted_proxies` com a faixa do proxy Azure e desligar a flag.

Regressão: `test/integration/security/session_fingerprint_test.rb` (6 testes — 4 cobrem o modo estrito, 2 cobrem o modo UA-only incluindo "UA diferente continua sendo rejeitado").

## Riscos aceitos pela Firjan

### `/api/translations/pt/app.admin` acessível sem autenticação

O endpoint público `/api/translations/:locale/:scope` retorna todas as strings i18n do scope solicitado. Para `app.admin` (e similares), os labels de UI da seção administrativa ficam acessíveis a qualquer caller — incluindo nomes de campos de configuração dos gateways de pagamento (`payzen_password`, `client_secret`, `seller_id`, `pagseguro_token` etc.).

**Não vaza valores** (a string `"Senha"` é exposta, não a senha em si), apenas a estrutura da UI admin.

**Decisão de produto (Claupper, 2026-05-17):** risco aceito como baixo. Restringir o scope `app.admin` a usuários privileged forçaria refator no bootstrap do frontend Angular (carregar bundles diferentes de tradução conforme role), com custo desproporcional ao ganho de segurança. O endpoint segue público.

## Entrega da rodada v3 (em aberto)

Pentest browser-driven em 2026-05-17 (relatório completo em [`pentest-2026-05-17.md`](pentest-2026-05-17.md)) descobriu 22 achados, dos quais 7 críticos. Esta rodada fecha 6 deles (itens 7-11, 13 e 22 do relatório). O item 5 (auto-login sem email confirmation) foi deixado de fora por decisão do Alex.

### Mudanças desta rodada (3 commits)

**Commit 1 — `(security) close IDOR on show actions for orders/invoices/reservations/credits/supporting_document_files`**

5 controllers tinham `show` action sem `authorize`. Member logado lia recurso de qualquer outro. Mesma anatomia em todos:

| Endpoint | Vazava | Fix |
|---|---|---|
| `GET /api/orders/:id` | cart token + invoice_id de outros | `authorize @order` (policy já estava OK) |
| `GET /api/credits/:id` | metadados administrativos | `authorize @credit` + `CreditPolicy#show?` (admin-only) |
| `GET /api/supporting_document_files/:id` | filename + user_id (PII/LGPD) | `authorize @file` + `show?` espelhando `download?` |
| `GET /api/invoices/:id` | total + items + reference + chained_footprint | `authorize @invoice` + `show?` espelhando `download?` |
| `GET /api/reservations/:id` | `user_full_name` + padrão de uso | `authorize @reservation` + `show?` espelhando `update?` |

Regressão: `test/integration/security/idor_show_actions_test.rb` (9 testes).

**Commit 2 — `(security) restrict Getnet endpoints to current_user and require cart context`**

`API::GetnetController` herdava apenas `authenticate_user!`. Achados do pentest (item #13):
- `token_card` aceitava `customer_id` arbitrário (validation oracle + tokenização cross-user). Fix: novo `enforce_customer_is_current_user` rejeita mismatch; o payload Getnet sempre usa `current_user.id`.
- `create_payment` / `confirm_payment` crashavam com NoMethodError sem `cart_items` (177KB de stack). Fix: `require_cart_items` retorna 422 limpo.

Regressão: `test/integration/security/getnet_authz_test.rb` (4 testes — só os vetores do pentest, sem expandir pra `sdk_test` que não estava no relatório).

**Commit 3 — `(security) validate and sanitize user-controlled text fields (XSS hardening)`**

`PUT /api/members/:id` aceitava `<script>` / `<svg onload>` em `username`, `first_name`, `last_name` (item #22). Apesar do Angular `{{ }}` escapar, os valores chegam a mailers (10+ templates), PDFs gerados, e `publicProfile.html.erb` que usa `ng-bind-html`.

- **Profile**: `NAME_FORMAT = /\A[\p{L}\p{N}\s'.\-,()]+\z/u` aplicado **apenas a `first_name` e `last_name`** (os campos que o pentest exerceu). Aceita `João D'Ávila`, `Silva-Santos`. Rejeita HTML delimiters.
- **User#username**: `/\A[a-zA-Z0-9._\-]+\z/`.

Outros campos (`social_name`, `mother_name`, `interest`, `software_mastered`, etc.) **não foram tocados** — não foram exercidos no pentest e endurecer global sem evidência aumenta risco de quebrar users existentes. Se aparecerem em report futuro, harden cirúrgico ali.

Regressão: `test/integration/security/xss_hardening_test.rb` (4 testes).

**Pré-deploy obrigatório**: rodar em produção (Rails console read-only) antes do deploy:
```ruby
Profile.find_each { |p| puts p.id unless p.valid? }
```
Se houver IDs no output, ajustar `NAME_FORMAT` ou hot-fix em bulk antes do deploy.

### Itens do pentest 2026-05-17 NÃO cobertos por esta rodada (decisão Alex)

- **#5 Auto-login sem email confirmation** — fica para outra janela (decisão pendente sobre Devise.confirmable).
- **#6, #14, #21 Verbose error pages e `/rails/info/routes`** — verificar em produção (provavelmente já gated por `Rails.env.production?`, mas confirmar).
- **#15 PagSeguro/notify HMAC** — outra rodada.
- **#16-18 Security headers** (CSP fraca, sem HSTS/Permissions-Policy/COOP/CORP/COEP) — defense in depth, outra rodada.
- **#20 `/health` campo `stats`** — verificar o que é em `health_controller.rb`.
- **#1, #2 LGPD signup excesso de coleta / `is_allow_contact` default true** — decisão de produto.
- **#3 `/uploads/custom_asset_file/:id` previsível** — verificar se vale signed URLs.

## Entrega da rodada v2 (em aberto)

Reporte do Ramadan/Claupper em 2026-05-17 (pós-deploy da v1): IDOR persiste em `/api/members/:id` e `/api/groups`. Reproduzido com sessão do user `1940` (cenos61984@7novels.com, role `member`).

Investigação: o fix v1 da `UserPolicy#show?` está deployado e bloqueia o caso `member→outro-member` em `show`. O que o pentest está vendo é:

1. **`GET /api/members` (index) + `GET /api/last_subscribed/:n`** entregam email/telefone de toda a base opt-in para qualquer caller logado — vetor de **enumeração em massa**, não exposto via `show` mas presente na listagem.
2. **`GET /api/groups`** expõe contagem de membros por grupo (`users.count`) a qualquer caller (anônimo no signup modal + member logado).

> **Sobre `/api/projects/:id`:** chegou a ser tratado nesta rodada (commits intermediários adicionavam `authorize` + `ProjectPolicy#show?`), mas **revertido em 2026-05-17 por decisão do Alex**. A listagem e a visualização de projetos é **intencionalmente pública** no Fab-manager — funciona como portfólio do fablab e não é IDOR. Drafts visíveis a quem souber o slug é comportamento aceito; quem não é autor/colaborador não pode editar (já coberto por `ProjectPolicy#update?`).

**Achado importante:** o upstream `sleede/fab-manager` lançou em 2026-03-31 o commit `fa5489ae6 (security) restrict member api personal data` cobrindo exatamente o item (1). Aproveitamos o mecanismo e adaptamos para os campos extras Firjan (CPF, RG, mother_name, endereço, financial_responsible_*) e para a condição de "self não restringe" — sem isso o member não consegue ver o próprio CPF na tela de edição de perfil.

### Mudanças desta rodada

| Frente | Arquivo | Mudança |
|---|---|---|
| 1) Members `show`/index/`last_subscribed` | `app/controllers/api/members_controller.rb` | `@restricted_member_show = !current_user.privileged? && current_user.id != @member.id` (self ou privileged → não restringe). `@restricted_member_index = !current_user.privileged?`. `@public_last_subscribed = true` para a rota pública. |
| | `app/services/members/members_service.rb` | `last_registered` sem parâmetro, limite fixo 10 (era controlado pelo cliente — DoS de enumeração). |
| | `app/views/api/members/_member.json.jbuilder` | PII (CPF, RG, mother_name, endereço, IP, financial_responsible_*, invoicing, statistic, subscription, credits, etc.) envolvida em `unless @restricted_member_show`. |
| | `app/views/api/members/index.json.jbuilder` | **Mais rigoroso que upstream `fa5489ae6`**: para qualquer caller não-privileged (incluindo logado), entrega apenas `id` + `maxMembers`. Sem email, username, slug, nome, group_id, phone, etc. Justificativa: a Firjan esconde o diretório público de membros via feature flag, então member não-priv não tem caso de uso legítimo desse endpoint, e qualquer leak vira vetor de enumeração da base. Admin/manager continua recebendo a payload completa. Branch `@public_last_subscribed` entrega só nome + avatar. |
| | `app/views/api/members/show.json.jbuilder` | `reservations`/`invoices`/`tags`/`merged_at`/etc. atrás de `unless @restricted_member_show`. |
| 2) Groups | `app/controllers/api/groups_controller.rb` | `@restricted_groups_index = !current_user&.privileged?`. Endpoint segue público (necessário ao signup modal). |
| | `app/views/api/groups/_group.json.jbuilder` | `users.count` envolvido em `unless @restricted_groups_index`. |

### Testes de regressão adicionados

| Arquivo | Cobre |
|---|---|
| `test/integration/members/as_member_test.rb` (expandido) | Member não vê phone na listagem; admin continua vendo; `last_subscribed` nunca devolve email; cap server-side de 10; self continua vendo próprio CPF/endereço. |
| `test/integration/groups/index_test.rb` (novo) | Anon e member não veem `users.count`; admin vê. |

### Decisão sobre `is_allow_contact`

Default no banco (`true` desde 2014) e no Angular controller (`$scope.user.is_allow_contact: true`) **continua intocado**. A mudança de default impacta o diretório público de membros (`Members::ListService` e `Members::MembersService`) e é decisão de produto/LGPD da Firjan, não de patch técnico. Após esta rodada, o `is_allow_contact` segue funcionando como flag de "aparece no diretório" — ele não regrança leitura de PII nem na `show?` (fechado na v1) nem nas views (fechado na v2 pela minimização).

### Pós-deploy

- [ ] Felipe agendar deploy de `feat/firjan-security-idor-v2` em janela combinada.
- [ ] Após deploy: confirmar com Claupper/Ramadan que os 3 vetores estão fechados (re-rodar o teste do user 1940 e checar `users.count` em groups).
- [ ] Excluir user 1940 (cenos61984@7novels.com, slug `tedede`) da produção — pendência ainda aberta da v1.

## Entrega da rodada v1 (em produção)

- ✅ **`UserPolicy#show?` corrigido** — vetor IDOR de `GET /api/members/:id` reportado pelo pentest está fechado. Validado em dev local apontando para o DB de produção em 2026-05-12.
- ✅ **Teste de regressão** em `test/integration/members/as_member_test.rb` para impedir que rebases futuros do upstream reintroduzam a cláusula vulnerável.
- ✅ **Baseline da superfície de IDOR** — analisador estático reutilizável (`audit_idor_baseline.rb`) + inventário gerado (`inventory_2026-05-07.md`) cobrindo 88 controllers / 341 actions / 67 policies.
- ❌ **`verify_authorized` global tentado e revertido** — quebrava todos os endpoints porque a exceção levantada não era capturada pelo rescue existente. Detalhes em "Status das fases" abaixo.
- ⏳ **`/api/projects/:id`** — investigado e descartado como IDOR em 2026-05-17. Listagem e show de projects são **intencionalmente públicos** (portfólio do fablab). Edição segue restrita ao autor/colaborador/admin via `ProjectPolicy#update?`. Não é vetor de vazamento de PII.

## Origem

Vulnerabilidade reportada por pentest externo (Rhamadan De Paiva Leal) e repassada pela Firjan (Claupper) em 2026-05-07. Log do request original capturado em 2026-03-06.

**Endpoints confirmados como vulneráveis:**

- `GET /api/members/:id` — corrigido na rodada **v1** (`UserPolicy#show?`).
- `GET /api/members` (listagem) e `GET /api/last_subscribed/:n` — enumeração massiva de email/telefone reportada pós-v1; tratada na **v2** com o patch upstream `fa5489ae6` adaptado.
- `GET /api/groups` — exposição de `users.count` reportada pós-v1; tratada na **v2** restringindo a admin/manager.
- `GET /api/projects/:id` — chegou a aparecer no report inicial do Claupper como suspeita, mas após investigação foi **descartado como vetor**: listagem e show de projects são intencionalmente públicos (portfólio do fablab), e a edição segue protegida por `ProjectPolicy#update?`.

## Arquivos

- `audit_idor_baseline.rb` — analisador estático. Percorre `app/controllers/{api,open_api/v1}` e `app/policies/`, gera markdown com inventário de actions, status de `authorize`/`policy_scope` e checagens de policy.
- `inventory_YYYY-MM-DD.md` — saída do analisador. Regenerada conforme o trabalho avança.
- `README.md` (este arquivo) — resumo curado das conclusões da Fase 0 e plano operacional das fases seguintes.

## Como regenerar o inventário

```bash
ruby doc/security/audit_idor_baseline.rb > doc/security/inventory_$(date +%Y-%m-%d).md
```

Sem dependência de Rails boot ou DB — análise puramente estática.

## Resumo da baseline (2026-05-07)

| Métrica | Valor |
|---|---|
| Controllers analisados (`api/` + `open_api/v1/`) | 88 |
| Actions públicas | 341 |
| 🔴 Actions sem `authorize` (CRUD) | 23 (ver triagem abaixo) |
| 🟡 Coleções sem `policy_scope` | 53 |
| Policies analisadas | 67 |
| 🔴 Predicates sem checagem de posse nem role | 2 |
| 🔵 Predicates com cláusulas OR a revisar | 3 (inclui o vetor confirmado) |

## Triagem das 23 actions 🔴

### Candidatos reais para fix (precisam de `authorize`)

| Controller#action | Risco |
|---|---|
| `projects#show` | **Confirmado IDOR** pelo Claupper |
| `projects#create` | Verificar quem pode criar |
| `supporting_document_files#show` | 🔥 **Crítico LGPD** — documentos pessoais (RG, CPF, comprovantes) sem authorize |
| `notifications#update` | Pode permitir marcar notificação de outro usuário |
| `abuses#create` | Verificar se anônimo pode criar reports infinitos |
| `admins#destroy` | Verificar quem pode excluir admins |
| `trainings_pricings#update` | Precificação — quem pode alterar? |
| `open_api/v1/machines#create/update/show/destroy` | OpenAPI sem auth de cliente? |
| `open_api/v1/plans#show` | Idem |
| `open_api/v1/spaces#show` | Idem |

### Provavelmente públicos por design (verificar e marcar `skip_before_action :authenticate_user!`)

Recursos de catálogo do fablab que aparecem para visitantes não-logados:

`events#show`, `machines#show`, `plans#show`, `products#show`, `product_categories#show`, `spaces#show`, `trainings#show`, `custom_assets#show`, `stylesheets#show`, `translations#show`

Esses não precisam de `authorize`. Caso o `verify_authorized` global seja reintroduzido no futuro (ver Pendências em aberto), cada um precisa de `skip_authorization` declarado.

## Triagem das 3 policies 🔵 (cláusulas OR)

| Policy#predicate | Análise |
|---|---|
| `UserPolicy#show?` | **Bug confirmado.** Cláusula `(record.is_allow_contact && record.member?)` libera leitura completa para qualquer logado. **Fix prioritário Fase 3a.** |
| `UserPolicy#update?` | Cláusulas: admin / manager / self. Estruturalmente seguro. **Não-bug**, mas pareceu OR a verificar. |
| `ReservationPolicy#update?` | Cláusulas: admin / manager / owner. Estruturalmente seguro. **Não-bug**. |

## Limitações da baseline

1. **Análise estática.** Não vê herança de filtros via `concerns/`, includes dinâmicos, ou autorização feita via `find` scoped (`current_user.x.find(params[:id])`). Falsos positivos no controller-side são esperados.
2. **Cláusulas OR só analisadas em policies.** Se houver `if`/condicional fora de policy fazendo autorização, não pega.
3. **Serializers (jbuilder) não analisados.** Mesmo com policy correta, view pode vazar campos sensíveis. Caso do `members#show` mistura policy permissiva + serializer largo.

## Log scan de produção (item do plano Fase 0)

**Não executado** — acesso ao log de produção (nginx/Rails) não disponível na worktree local. Sem Sentry (ver `memory: project_gap_sentry_producao.md`), a varredura por padrões de enumeração precisa rodar diretamente nos servidores da Firjan via acesso SSH.

**Próximo passo:** alinhar com Claupper se acesso a logs é viável, ou aceitar que ausência de evidência de exploração será documentada como "não verificável retroativamente". Para a Fase 5 (artefato LGPD), o argumento defensável é: pentest reportou em 2026-03-06, foram tomadas medidas corretivas em [data], não há sinal de exploração reportado por terceiros.

## Status das fases

### ❌ Fase 1 — `verify_authorized` global (tentada, revertida)

Foi tentado adicionar `after_action :verify_authorized, unless: :devise_controller?` em `API::APIController` para que toda action sem `authorize` levantasse erro alto.

**Resultado em ambiente local:** quebrou a renderização do site e gerou erro de autenticação em virtualmente todos os endpoints API. Causa: `Pundit::AuthorizationNotPerformedError` é subclasse diferente de `Pundit::NotAuthorizedError`. O `rescue_from Pundit::NotAuthorizedError` existente em `ApplicationController` (que responde 403) **não captura** a primeira, então cada ação que não chama `authorize` virou 500 não tratado. Como o baseline mostra ~76 actions assim, o efeito foi catastrófico.

**Decisão:** revertido em 2026-05-12. A safety net global só pode ser reintroduzida depois de:
1. Cada action ter `authorize` explícito OU `skip_authorization` deliberado
2. Adicionar `rescue_from Pundit::AuthorizationNotPerformedError` em `ApplicationController` retornando 403 (ou 500 com log — depende da política)
3. Validar em staging antes de produção, não direto no main

Plano original assumia "tests vão falhar e a gente trata" — mas em desenvolvimento o erro acontece em runtime de navegador, não só em test. Lição: mudanças de safety net global precisam de uma fase de preparação prévia que sature os `authorize`/`skip_authorization` antes de ligar o switch.

### ✅ Fase 3a — `UserPolicy#show?` (entregue)

Removida a cláusula `(record.is_allow_contact && record.member?)`. Predicate final:

```ruby
def show?
  user.admin? || user.manager? || (user.id == record.id)
end
```

`is_allow_contact` é mantido como flag funcional para o diretório de membros (`Members::ListService` e `Members::MembersService`), onde filtra quem aparece disponível para contato. Não regrança leitura do perfil completo.

**Escopo deliberadamente limitado nesta fase, decidido em 2026-05-12:**
- Não inclui troca de default da coluna (`true` → `false`) — decisão de produto sobre LGPD opt-in fica para alinhamento com Claupper.
- Não inclui troca do default `$scope.user.is_allow_contact: true` em `app/frontend/src/javascript/controllers/application.js`.
- Não inclui revisão do serializer em `app/views/api/members/show.json.jbuilder` (admin/manager/self ainda recebem PII completa — minimização LGPD em aberto).

**Regressão coberta:** `test/integration/members/as_member_test.rb` — 4 testes que falham se a cláusula vulnerável voltar (ex.: rebase upstream descuidado).

**Validação ao vivo em 2026-05-12 (dev local apontado para DB de produção, sessão de member 6):**

| Request | Pré-fix esperado | Pós-fix observado |
|---|---|---|
| `GET /api/members/1` (admin) | 403 (admin não é `member`) | 403 ✓ |
| `GET /api/members/7` (member, `is_allow_contact=true`) | **200 com PII completa** (vetor IDOR) | **403 ✓** |
| `GET /api/members/6` (self) | 200 | 200 ✓ |

Comportamento confirmado: o vetor reportado pelo pentest está fechado para o endpoint `members#show`.

## Pendências em aberto (após rodada v2)

A v2 cobre os três vetores reportados pelo Ramadan/Claupper em 2026-05-17 (members listing/show, groups, projects). Os itens abaixo permanecem para rodadas futuras, em alinhamento com Claupper/Felipe:

- **Default do `is_allow_contact`** — coluna do banco (default `true` desde a migration de 2014) e `$scope.user.is_allow_contact: true` em `app/frontend/src/javascript/controllers/application.js`. Mudar para `false` alinha com LGPD opt-in; impacta o diretório de membros. Após a v2 isso passa de vetor de IDOR para decisão de produto pura — a minimização já está aplicada nas views.
- **Fase 3c — `supporting_document_files#show`** — achado adicional da baseline. Action sem `authorize` em recurso de documentos pessoais (RG, CPF, comprovante). Severidade LGPD igual ou maior que o caso `members#show`.
- **Fase 3d** — Demais actions 🔴 da [`inventory_2026-05-07.md`](inventory_2026-05-07.md) ainda não tratadas (`abuses#create`, `admins#destroy`, `notifications#update`, `trainings_pricings#update`).
- **Fase 3e** — Sweep dos Firjan custom controllers (Getnet, PagSeguro, brazillian_data — todos 🟢 no baseline, mas conferência manual recomendada).
- **Fase 4** — OpenAPI sweep (`open_api/v1/machines`, `plans`, `spaces` com 🔴).
- **Fase 5** — Documentação LGPD formal: timeline, endpoints afetados, mitigações aplicadas, evidências de ausência de exploração (limitada pela não-existência de Sentry em prod).
- **Reintrodução de `verify_authorized` (Fase 1 revisitada)** — depois que todas as actions estiverem com `authorize`/`skip_authorization` declarados, e o `rescue_from Pundit::AuthorizationNotPerformedError` estiver em `ApplicationController`. Sem essa preparação, qualquer tentativa global quebra a aplicação.
