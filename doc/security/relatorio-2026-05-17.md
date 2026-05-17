# Relatório de segurança — Fab-manager Firjan

**Data:** 17 de maio de 2026
**Branch:** `feat/firjan-security-idor-v2`
**Origem:** vulnerabilidade reportada por pentest externo (Rhamadan De Paiva Leal, repassada pela Firjan em 2026-05-07) + pentest interno browser-driven em 2026-05-17.

---

## Resumo executivo

Foram executadas 3 rodadas de correção em maio/2026. A primeira já está em produção. As outras duas estão na branch `feat/firjan-security-idor-v2`, aguardando squash-merge em `feat/firjan-report` e janela de deploy.

| Rodada | Status | Vulnerabilidades fechadas | Commits |
|---|---|---|---|
| **v1** | ✅ Em produção | 1 IDOR crítico (members#show) | `f8f3d1675` |
| **v2** | 🚧 Em revisão | 2 leaks via listing (members, groups) | `92e8027e9` + `e29c3ec13` |
| **v3** | 🚧 Em revisão | 5 IDORs em show actions + 2 falhas Getnet + 1 XSS Stored | `86e968b6f` + `85907c65e` + `d6673a3cc` + `f8f97afdf` + doc |

**Total:** 11 vulnerabilidades exploráveis fechadas, 25 testes de regressão adicionados.

---

## Linha do tempo

| Data | Evento |
|---|---|
| 2026-03-06 | Pentester externo (Rhamadan) reporta IDOR em `/api/members/:id` |
| 2026-05-01 | Felipe aprova 15-20h pra auditoria + fix |
| 2026-05-07 | Claupper repassa o reporte com detalhes (usuário 1940 vazando PII completa em produção) |
| 2026-05-12 | **Rodada v1 entregue** — `UserPolicy#show?` corrigida; baseline de IDOR (88 controllers, 341 actions, 67 policies) gerada |
| 2026-05-13 | Deploy v1 em produção |
| 2026-05-17 | Ramadan reporta que IDOR persiste em members + groups — sessão do user 1940 ainda consegue ler dados |
| 2026-05-17 | **Rodada v2 entregue** — aplicado patch upstream `fa5489ae6` adaptado pro schema Firjan + groups + dev configura MCP DBeaver |
| 2026-05-17 | **Pentest interno browser-driven** identifica 22 achados (7 críticos) — relatório em `doc/security/pentest-2026-05-17.md` |
| 2026-05-17 | **Rodada v3 entregue** — 8 dos 22 achados fechados (5 IDORs em show + Getnet + XSS) |

---

## Rodada v1 — fix do vetor reportado (em produção)

**Vulnerabilidade:** `UserPolicy#show?` continha a cláusula `(record.is_allow_contact && record.member?)` — qualquer membro autenticado conseguia ler o perfil completo (CPF, RG, nome da mãe, endereço, IP) de qualquer outro membro cuja flag `is_allow_contact` fosse `true` (default desde 2014).

**Fix:** removida a cláusula. `show?` agora exige admin, manager, ou self.

**Entregáveis:**
- `app/policies/user_policy.rb` — predicate corrigido
- `doc/security/audit_idor_baseline.rb` — analisador estático reutilizável
- `doc/security/inventory_2026-05-07.md` — inventário de 88 controllers / 341 actions / 67 policies
- `doc/security/README.md` — documentação da rodada
- `test/integration/members/as_member_test.rb` — 4 testes de regressão

**Validação:** reproduzido em dev apontando para DB de produção:
- `GET /api/members/1940` (member→member) antes do fix: 200 com PII completa
- Depois do fix: 403

---

## Rodada v2 — listing + groups (em revisão)

**Vulnerabilidades reportadas pelo Ramadan pós-deploy da v1:**

1. **Enumeração via `/api/members` + `/api/last_subscribed/:n`**: qualquer membro logado baixava email/telefone de toda a base opt-in (centenas/milhares de users). A v1 só fechou o `show`, não o listing.
2. **`/api/groups` expõe `users.count`**: contagem de membros por grupo visível a qualquer caller, incluindo anônimo no signup modal.

**Fix:** aplicado o patch oficial do upstream `sleede/fab-manager` (`fa5489ae6` de 2026-03-31) adaptado para:
- A) cobrir os campos Firjan extras (CPF, RG, mother_name, endereço, financial_responsible_*) — todos atrás da flag `@restricted_member_show`/`@restricted_member_index`.
- B) `last_subscribed` cap server-side em 10 (era controlado pelo cliente, vetor de DoS/enumeração).
- C) Self (membro vendo o próprio perfil) **não** é restringido — necessário para a tela de edição de perfil.
- D) Members listing para non-priv retorna apenas `id + maxMembers` (mais rigoroso que upstream, alinhado com a feature flag Firjan que esconde o diretório público).
- E) Groups listing esconde `users.count` para non-priv; endpoint segue público para o signup modal funcionar.

**Entregáveis:**
- `app/controllers/api/members_controller.rb`, `app/services/members/members_service.rb`
- `app/views/api/members/{_member,index,show}.json.jbuilder`
- `app/controllers/api/groups_controller.rb`, `app/views/api/groups/_group.json.jbuilder`
- `test/integration/members/as_member_test.rb` (expandido para 8 testes), `test/integration/groups/index_test.rb` (novo, 3 testes)
- `.mcp.json` + `CLAUDE.md` (regra SELECT-only para MCP DBeaver, gitignored)

**Validação:** reproduzido com sessão de member real no DB de produção:
- `GET /api/members?size=10` antes: chave `email` exposta para non-priv. Depois: apenas `id` e `maxMembers`.
- `GET /api/groups` antes: chave `users` exposta. Depois: ausente para non-priv.
- `GET /api/last_subscribed/9999` antes: 9999 resultados. Depois: 10 fixo, sem email/username.

---

## Rodada v3 — pentest interno (em revisão)

**Origem:** pentest browser-driven executado em 2026-05-17 com membro recém-criado (Karex Pentest, id 1948), apenas role `member`. Encontrou 22 falhas — relatório completo em `doc/security/pentest-2026-05-17.md`.

**Severidades fechadas nesta rodada (8 críticas, 5 controladores):**

### IDOR em show actions (commit `86e968b6f`)

5 controllers tinham `show` sem `authorize`. Membro logado conseguia ler qualquer recurso só mudando o `:id`:

| Endpoint | Vazava |
|---|---|
| `/api/orders/:id` | token do carrinho, invoice_id, total |
| `/api/invoices/:id` | total, items, descrição, referência |
| `/api/reservations/:id` | nome completo do dono (`user_full_name`), padrão de uso |
| `/api/credits/:id` | metadados administrativos |
| `/api/supporting_document_files/:id` | filename + user_id de documentos pessoais (RG, CPF, comprovantes) |

**Fix:** mesma anatomia em todos — `authorize @record` no controller + `show?` na policy. Admin/manager mantêm acesso total. Self vê próprio.

### Getnet sem autorização (commit `85907c65e`)

`API::GetnetController` herdava só `authenticate_user!`. Vetores:
- `token_card` aceitava `customer_id` arbitrário → atacante tokenizava cartão sob identidade de outro membro, e/ou usava a credencial Getnet da Firjan como **oráculo de validação de números de cartão** (uso fraudulento via proxy).
- `create_payment` / `confirm_payment` sem `cart_items` → NoMethodError + 177KB de stack trace HTML.

**Fix:**
- `enforce_customer_is_current_user` rejeita mismatch de `customer_id`; o payload Getnet sempre usa `current_user.id`.
- `require_cart_items` retorna 422 limpo em vez de stack trace.

### XSS Stored (commit `d6673a3cc`, refinado em `f8f97afdf`)

`PUT /api/members/:id` aceitava `<script>` / `<svg onload>` em `User#username`, `Profile#first_name`, `Profile#last_name`. O Angular escapa por default em `{{ }}`, **mas** os valores chegam a:
- 10+ templates de mailer (`app/views/notifications_mailer/`)
- PDFs gerados
- `publicProfile.html.erb` que usa `ng-bind-html`

**Fix:**
- `Profile#first_name`, `#last_name`: validação format whitelist `\p{L}\p{N}\s'.\-,()`. Aceita `João D'Ávila`, `Silva-Santos`. Rejeita HTML.
- `User#username`: validação format `[a-zA-Z0-9._\-]+`.

**Escopo deliberadamente restrito:** apenas os campos exercidos no pentest. `social_name`, `mother_name`, `interest`, etc. não foram tocados — se aparecerem em report futuro, recebem patch cirúrgico ali.

---

## Estado atual

### Em produção
- v1 (commit `f8f3d1675` em `feat/firjan-report`)

### Aguardando deploy (na `feat/firjan-security-idor-v2`)
- v2 (commits `92e8027e9` + `e29c3ec13`)
- v3 (commits `86e968b6f` + `85907c65e` + `d6673a3cc` + `f8f97afdf` + doc `32b4ef4a4`)

### Para deploy
1. Squash-merge `feat/firjan-security-idor-v2` → `feat/firjan-report`
2. **Pré-deploy obrigatório do commit XSS:** rodar em produção (Rails console read-only) `Profile.find_each { |p| puts p.id unless p.valid? }`. Se houver IDs no output, ajustar `NAME_FORMAT` ou patch em bulk antes do deploy. Os profiles existentes não foram testados contra a nova validação.
3. Combinar janela com Felipe.

---

## Pendências (não cobertas nesta entrega)

Itens conhecidos do pentest 2026-05-17 que ficaram para rodadas futuras:

| Item | Categoria | Decisão |
|---|---|---|
| Auto-login sem email confirmation | Account takeover | Decisão pendente (Devise.confirmable) — Alex pediu pra ignorar nesta rodada |
| Verbose error pages do Rails (226KB stack) | Info disclosure | Verificar em prod (provavelmente já gated por `Rails.env.production?`) |
| `/rails/info/routes` acessível em dev | Info disclosure | Verificar em prod |
| `/health` campo `stats` | Info disclosure | Auditar `health_controller.rb` |
| `/api/pagseguro/notify` webhook | Validação HMAC | Próxima rodada — confirmar com o PagSeguro |
| CSP fraca (sem `default-src`, `script-src`) | Defense in depth | Próxima rodada |
| HSTS / Permissions-Policy / COOP / CORP ausentes | Defense in depth | Próxima rodada |
| LGPD: signup coleta excessiva (CPF/RG/mãe pré-validação) | Decisão de produto | Alinhamento com Claupper |
| `is_allow_contact: true` por default | Decisão de produto | Alinhamento com Claupper |
| `/uploads/custom_asset_file/:id` previsível | Defense in depth | Avaliar signed URLs |

### Operacionais
- Deletar o user `cenos61984@7novels.com` (id 1940, slug `tedede`) — usuário de teste do pentester original que ainda está em produção.
- Deletar o user `karex92055@dardr.com` (id 1948) — usuário do pentest interno desta rodada (já reverti o payload XSS armado nele).
- MCP DBeaver para `Fabmanager Prd` está bloqueado por bug no `dbeaver-mcp-server@1.3.0` que ignora propriedades SSL — workaround pendente, não afeta produção.

---

## Validação

- **v1**: validado em dev local apontando para DB de produção com sessão do member 6, em 2026-05-12.
- **v2**: validado via browser MCP com member real em 2026-05-17 — 5 vetores reproduzidos antes/depois do fix.
- **v3**: validado via browser MCP com member 1948 em 2026-05-17 — 8 vetores reproduzidos antes/depois do fix.

**Testes de regressão automatizados** (25 no total, em `test/integration/`):
- `members/as_member_test.rb` (8)
- `groups/index_test.rb` (3)
- `security/idor_show_actions_test.rb` (9)
- `security/getnet_authz_test.rb` (4)
- `security/xss_hardening_test.rb` (4)

**Pendente do lado da execução:** rodar `scripts/tests.sh` localmente para confirmar os testes passam (trava em ambiente não-interativo, requer terminal real para responder prompts de chaves Stripe/OAuth).

---

## Documentação técnica complementar

- `doc/security/README.md` — visão consolidada das 3 rodadas
- `doc/security/pentest-2026-05-17.md` — relatório completo do pentest interno (22 achados)
- `doc/security/audit_idor_baseline.rb` + `inventory_2026-05-07.md` — analisador estático e baseline
