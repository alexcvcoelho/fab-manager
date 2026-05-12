# Auditoria de segurança — IDOR

Diretório de artefatos da Task 2 (maio/2026): auditoria e correção de autorização no Fab-manager Firjan.

## Origem

Vulnerabilidade reportada por pentest externo (Rhamadan De Paiva Leal) e repassada pela Firjan (Claupper) em 2026-05-07. Log do request original capturado em 2026-03-06.

**Endpoints confirmados como vulneráveis:**

- `GET /api/members/:id` — retorna perfil completo (CPF, RG, nome da mãe, endereço, IP, etc.) de qualquer membro com `is_allow_contact: true` para qualquer usuário autenticado.
- `GET /api/projects/:id` — IDOR confirmado pelo pentester (escopo a investigar).

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

Esses não precisam de `authorize`, mas precisam de declaração explícita de "público" para que o Pundit `verify_authorized` (a ser introduzido na Fase 1) não derrube.

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

### ✅ Fase 1 — Defesas estruturais (concluída)

`API::APIController` agora declara `after_action :verify_authorized` (Pundit). Qualquer action que termine sem chamar `authorize(...)` ou `skip_authorization` levanta `Pundit::AuthorizationNotPerformedError`, transformando "esqueci de autorizar" de buraco silencioso em erro alto no teste.

**Decisões deliberadas:**
- **Só `verify_authorized` por enquanto** — não `verify_policy_scoped`. Tem muito collection method custom (`search`, `list`, `last_published`, `current`) que escapariam da regra "só index". Cobrir esses casos vira passo dentro da Fase 3 ou uma sub-fase separada se necessário.
- **Sem mudar autenticação default agora** — cada controller continua opt-in pra `authenticate_user!`. Misturar "muda quem precisa estar logado" com "muda quem está autorizado" duplica risco de regressão. Authentication baseline pode ser endurecida em fase posterior.
- **`unless: :devise_controller?`** — ações do Devise (sign_in, sign_up etc.) não usam Pundit.

**Como rodar a suite localmente (você):**

```bash
# Setup das envs (uma vez)
# Garantir que .env tem LOG_LEVEL=debug (ou outro valor não-vazio)

# Rodar suite completa
scripts/tests.sh

# Ou só os controllers de API (mais rápido pra triar)
scripts/tests.sh test/integration/
```

**O que esperar:**

Com base na baseline ([`inventory_2026-05-07.md`](inventory_2026-05-07.md)), prevemos **dezenas de violações** — uma para cada action sem `authorize`. Categorias esperadas:

| Categoria | Quantidade aproximada | Tratamento na Fase 2 |
|---|---|---|
| Catálogo público (events#show, machines#show, plans#show, etc.) | ~13 | Adicionar `skip_authorization` no método com comentário explicando |
| Vetores reais de IDOR (projects#show, supporting_document_files#show, etc.) | ~10 | Adicionar `authorize` + policy correta na Fase 3 |
| Collection methods custom (search, list, last_published) | ~vários | Decidir caso a caso: `authorize :resource, :action?` ou `skip_authorization` se realmente público |
| Falsos positivos da heurística estática | poucos | Validar manualmente — pode ter `authorize` em forma que o regex não detectou |

A saída do `scripts/tests.sh` vira o ponto de partida da Fase 2.

### Próximas fases
- **Fase 2 (3-4h)** — Triagem das quebras: classificar entre "público legítimo", "esqueceu auth", "esqueceu authorize". Confirmar/refutar candidatos da seção acima.
- **Fase 3 (6-8h)** — Fixes na ordem: (3a) `UserPolicy#show?` + serializer de members; (3b) `ProjectPolicy` + `ProjectsController`; (3c) `supporting_document_files`; (3d) demais 🔴 confirmados; (3e) Firjan custom (Getnet, PagSeguro, brazillian_data — todos 🟢 no baseline, mas verificar manualmente).
- **Fase 4 (1-2h)** — OpenAPI sweep.
- **Fase 5 (1h)** — Documentação LGPD: timeline, endpoints, fixes, evidências.
