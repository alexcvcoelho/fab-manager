# Auditoria de segurança — IDOR

Diretório de artefatos da Task 2 (maio/2026): auditoria e correção de autorização no Fab-manager Firjan.

## Entrega desta branch (resumo)

- ✅ **`UserPolicy#show?` corrigido** — vetor IDOR de `GET /api/members/:id` reportado pelo pentest está fechado. Validado em dev local apontando para o DB de produção em 2026-05-12.
- ✅ **Teste de regressão** em `test/integration/members/as_member_test.rb` para impedir que rebases futuros do upstream reintroduzam a cláusula vulnerável.
- ✅ **Baseline da superfície de IDOR** — analisador estático reutilizável (`audit_idor_baseline.rb`) + inventário gerado (`inventory_2026-05-07.md`) cobrindo 88 controllers / 341 actions / 67 policies.
- ❌ **`verify_authorized` global tentado e revertido** — quebrava todos os endpoints porque a exceção levantada não era capturada pelo rescue existente. Detalhes em "Status das fases" abaixo.
- ⏳ **`/api/projects/:id` e `supporting_document_files#show`** — também vulneráveis, ficam para próxima rodada de horas. Plano e contexto registrados nesta doc.

## Origem

Vulnerabilidade reportada por pentest externo (Rhamadan De Paiva Leal) e repassada pela Firjan (Claupper) em 2026-05-07. Log do request original capturado em 2026-03-06.

**Endpoints confirmados como vulneráveis:**

- `GET /api/members/:id` — **corrigido nesta entrega.** Retornava perfil completo (CPF, RG, nome da mãe, endereço, IP, etc.) de qualquer membro com `is_allow_contact: true` para qualquer usuário autenticado.
- `GET /api/projects/:id` — IDOR confirmado pelo pentester. **Não tratado nesta entrega**, fica para próxima rodada.

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

## Pendências em aberto (escopo intencionalmente fora desta entrega)

A entrega cobre o **vetor confirmado pelo pentest** (members#show). Os itens abaixo permanecem para uma próxima rodada de horas, em alinhamento com Claupper/Felipe:

- **Default do `is_allow_contact`** — coluna do banco (default `true` desde a migration de 2014) e `$scope.user.is_allow_contact: true` em `app/frontend/src/javascript/controllers/application.js`. Mudar para `false` alinha com LGPD opt-in; impacta o diretório de membros.
- **Serializer `show.json.jbuilder`** — admin/manager/self ainda recebem CPF, RG, nome da mãe, endereço, IP. Minimização LGPD pede revisão dos campos por necessidade real de exibição.
- **Fase 3b — `ProjectPolicy` + `ProjectsController#show`** — segundo IDOR reportado pelo Claupper. `ProjectsController#show` faz `Project.friendly.find(params[:id])` sem `authorize` e sem aplicar o `policy_scope`; permite ler drafts alheios. Fix: adicionar `authorize @project` no controller e definir `show?` no policy (público para `state == 'published'`, autor/colaborador/admin para drafts).
- **Fase 3c — `supporting_document_files#show`** — achado adicional da baseline. Action sem `authorize` em recurso de documentos pessoais (RG, CPF, comprovante). Severidade LGPD igual ou maior que o caso `members#show`.
- **Fase 3d** — Demais actions 🔴 da [`inventory_2026-05-07.md`](inventory_2026-05-07.md) ainda não tratadas (`abuses#create`, `admins#destroy`, `notifications#update`, `trainings_pricings#update`).
- **Fase 3e** — Sweep dos Firjan custom controllers (Getnet, PagSeguro, brazillian_data — todos 🟢 no baseline, mas conferência manual recomendada).
- **Fase 4** — OpenAPI sweep (`open_api/v1/machines`, `plans`, `spaces` com 🔴).
- **Fase 5** — Documentação LGPD formal: timeline, endpoints afetados, mitigações aplicadas, evidências de ausência de exploração (limitada pela não-existência de Sentry em prod).
- **Reintrodução de `verify_authorized` (Fase 1 revisitada)** — depois que todas as actions estiverem com `authorize`/`skip_authorization` declarados, e o `rescue_from Pundit::AuthorizationNotPerformedError` estiver em `ApplicationController`. Sem essa preparação, qualquer tentativa global quebra a aplicação.
