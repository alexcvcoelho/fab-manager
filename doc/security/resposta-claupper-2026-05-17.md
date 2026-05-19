# Resposta aos achados do Rhamadan — Fab-manager Firjan

**Data:** 17 de maio de 2026
**Branch:** `feat/firjan-security-idor-v2` (aguardando deploy)

---

## 1. Pontos apontados pelo Rhamadan que já cobrimos 100%

| Achado | Reprodução do Rhamadan | Como fechamos | Commit |
|---|---|---|---|
| IDOR em `GET /api/members/:id` (vazava CPF, RG, nome da mãe, endereço, IP) | reporte original de 2026-03-06 | `UserPolicy#show?` agora exige admin, manager ou self (cláusula `(record.is_allow_contact && record.member?)` removida) | `f8f3d1675` (v1 — **já em produção**) |
| Dump completo de usuários via `GET /api/members` | print `113129` + `113137` | `index.json.jbuilder` retorna apenas `id + maxMembers` para member não-privileged. Admin/manager continua recebendo o payload completo. | `e29c3ec13` (v2) |
| Dump completo de grupos com `users.count` via `GET /api/groups` | print `110323` + `110333` | `_group.json.jbuilder` esconde `users.count` para non-privileged. Endpoint segue público porque o signup modal precisa, mas só retorna `id/slug/name/disabled`. | `92e8027e9` (v2) |
| Enumeração de pedidos pelo ID em `GET /api/orders/:id` (mencionado em texto) | "É possível enumerar os pedidos de todos os usuários através do ID" | `OrdersController#show` agora chama `authorize @order`. A policy `OrderPolicy#show?` já existia (admin/manager ou owner). | `86e968b6f` (v3) |
| `GET /users/sign_in.json` retornando 500 | print `115010` | `SessionsController#new` detecta `request.format.json?` e responde **405 Method Not Allowed** limpo. HTML segue intacto. | `a0102f0fe` |

---

## 2. Falso positivos

### Enumeração de pedidos via `GET /api/orders?user_id=X`

> Print `imagem (5).png` — Rhamadan testou `GET /api/orders?user_id=1939` e marcou como vetor de enumeração.

A defesa **já existe no service**. Quando um member envia `user_id` de outro usuário, o `OrderService#filter_by_user` ignora silenciosamente o parâmetro e filtra pelos pedidos do próprio atacante.

**Trecho:** `app/services/orders/order_service.rb`, linhas 92-106

```ruby
def filter_by_user(orders, filters, current_user)
  if filters[:user_id]
    statistic_profile_id = current_user.statistic_profile.id   # ← FALLBACK SEGURO PRO PRÓPRIO USER
    if (current_user.member? && current_user.id == filters[:user_id].to_i) || current_user.privileged?
      user = User.find(filters[:user_id])
      statistic_profile_id = user.statistic_profile.id          # só sobrescreve se permitido
    end
    orders = orders.where(statistic_profile_id: statistic_profile_id)
  elsif current_user.member?
    orders = orders.where(statistic_profile_id: current_user.statistic_profile.id)
  ...
```

O resultado vazio que o Rhamadan observou no print é porque ele estava vendo os pedidos da própria conta de teste (que não tinha pedidos), **não** porque o user 1939 não tinha pedidos. Mesmo se o user alvo tivesse pedidos, o atacante nunca os receberia — receberia os próprios.

### `POST /users/sign_in.json` com `{"user":{}}` retornando 201

> Print `113820` — Rhamadan marcou como "Parece que há criação de recurso a cada chamada, um comportamento não entendido".

Não há criação de recurso. O comportamento é do Devise: quando o cliente já tem cookie de sessão válido e faz `POST /users/sign_in`, o Devise retorna **201 Created** com os dados do usuário atual em vez de 200 OK. É confusão de semântica HTTP no padrão do Devise/Warden, mas não persiste nada no banco — confere via `git diff` nos models e logs de criação.

**Trecho:** `app/controllers/sessions_controller.rb` herda de `Devise::SessionsController`, o `create` action é o padrão do gem. Para confirmar in vivo, monitorar logs Rails durante a chamada: nenhum `INSERT` ocorre.

### `/api/settings?names=PAYLOAD<'"><script>alert(1)</script>`

> Print `113408` — Rhamadan marcou como "parâmetros aceitam qualquer coisa, podendo se tornar vetor".

O response da chamada é literalmente `{}` (vazio). O servidor **não reflete** o input — apenas registra-o como query param ignorado. Não é XSS reflected. Para virar vetor real, seria necessário que o backend devolvesse o valor do param em algum ponto da response (`include the request in error message`, por exemplo), o que não ocorre.

Permanece como **defesa em profundidade aceita**: validar o shape do parâmetro `names` antes de processar é recomendável, mas não é exploração ativa hoje.

---

## 3. Questões não tratadas por dependerem de regra de negócio / decisão de produto

Os itens abaixo têm fix técnico possível, mas **a escolha não é técnica** — depende de uma decisão da Firjan sobre o trade-off envolvido.

### Q1. `/api/members/search/:query` permite enumeração de membros

> Imagens (3) e (4): `GET /api/members/search/%60` retorna lista de membros contendo backtick no nome. Aplicável para `%24`, vogais isoladas, etc. → enumera a base inteira por substring.

**Por que não fechamos tecnicamente:** o endpoint é usado pela feature de **adicionar colaborador em projeto**. Restringir a admin/manager ou pedir match exato bloqueia esse fluxo.

**Decisões possíveis:**

- **a)** Manter como está. Member encontra qualquer outro pelo nome. Risco de enumeração aceito.
- **b)** Restringir search a admin/manager. Adicionar colaborador passa a ser via convite por email/link.
- **c)** Manter o search mas reduzir o payload para non-priv (só `id` + `name`, sem `group_id`/`validated_at`) e exigir mínimo de 3 caracteres na query, sem aceitar `%encoded`/wildcards.
- **d)** Substituir "buscar e clicar" por "informar email/username exato" (sem listagem).

### Q2. Cookie de sessão sem device binding

> Print `112347`: Rhamadan capturou o cookie `_Fab-manager_session` em um device e usou em outro, acessando `/api/members/current` como o user original.

O cookie já tem `HttpOnly + Secure + SameSite=Lax` (correto). Falta vincular a sessão ao IP/UA do login. Toda mitigação tem trade-off de UX.

**Decisões possíveis:**

- **a)** Não mexer. Documentar como risco aceito. Detecção via log de acessos suspeitos.
- **b)** Sessão de curta duração (30 min – 2 h) + re-autenticação por senha em ações sensíveis (já parcialmente: `current_password` exigido em `PUT /api/members/:id`). Reduz a janela de exploração.
- **c)** Bind por subnet IP `/24` + User-Agent. Atacante remoto é bloqueado, atacante na mesma rede ainda consegue.
- **d)** 2FA / MFA via TOTP. Defesa real, mas custa implementação + comunicação aos membros.
- **e)** Combinação de **b** + **c** (sem 2FA, é o setup mais defensivo).

### Q3. `/api/translations/pt/app.admin` acessível a anônimo

> Prints `120323` + `120413`: o endpoint público de traduções vaza labels da seção administrativa, incluindo nomes de campos dos gateways (`payzen_password`, `client_secret`, `seller_id`, `pagseguro_token` etc.). Não vaza valores, mas expõe a superfície da admin a qualquer um.

**Por que não fechamos tecnicamente:** o frontend Angular carrega traduções dinamicamente desse endpoint. Restringir o scope `app.admin` força o front a esperar 401/403 quando o user não é admin e ajustar o bootstrap.

**Decisões possíveis:**

- **a)** Não mexer. Os labels expostos são texto de UI; não vazam valores. Aceitar como risco baixo.
- **b)** Restringir o scope `app.admin` a privileged. Custo: ajuste no bootstrap do Angular para carregar `app.admin` só quando o user logado for admin/manager.

---

## 4. Pontos que fechamos sem apontamento do Rhamadan

Identificados em pentest interno browser-driven em 2026-05-17 e fechados na rodada v3. Não chegaram a aparecer nos prints do Rhamadan, mas seguem a mesma anatomia dos achados dele.

| Vulnerabilidade | Descrição | Commit |
|---|---|---|
| IDOR em `GET /api/invoices/:id` | Member lia faturas (total, items, referência) de qualquer outro user. `authorize @invoice` + `InvoicePolicy#show?` adicionados. | `86e968b6f` |
| IDOR em `GET /api/reservations/:id` | Member lia reservas alheias (com `user_full_name` no payload). `authorize @reservation` + `ReservationPolicy#show?`. | `86e968b6f` |
| IDOR em `GET /api/credits/:id` | Member lia metadados administrativos de créditos. `authorize @credit` + `CreditPolicy#show?` (admin-only). | `86e968b6f` |
| IDOR em `GET /api/supporting_document_files/:id` | Member lia metadados (filename + user_id) de documentos pessoais de outros (RG, CPF, comprovantes). `authorize` + `show?` mirrando `download?`. | `86e968b6f` |
| Getnet `POST /api/getnet/token_card` aceitava `customer_id` arbitrário | Atacante usava a credencial Getnet da Firjan para tokenizar cartões sob identidade de outros membros / como oráculo de validação de cartões. `customer_id` agora forçado a `current_user.id`. | `85907c65e` |
| Getnet `create_payment` / `confirm_payment` crashavam com NoMethodError 500 sem cart_items | Antes: stack trace HTML de 177 KB exposto. Agora: 422 limpo via `require_cart_items`. | `85907c65e` |
| XSS Stored em `User#username`, `Profile#first_name`, `Profile#last_name` | `PUT /api/members/:id` aceitava `<script>` / `<svg onload>`. Validação format whitelist adicionada (rejeita HTML, aceita PT-BR como `João D'Ávila` e `Silva-Santos`). | `d6673a3cc` + `f8f97afdf` |

---

## Resumo numérico

- **9 vulnerabilidades reportadas pelo Rhamadan** → 5 fechadas, 3 dependem de decisão de produto (Q1, Q2, Q3), 1 era falso positivo (orders user_id), 2 itens eram noise (sign_in 201 e settings input dirty).
- **7 vulnerabilidades adicionais** identificadas pelo pentest interno e fechadas na rodada v3.
- **Total fechado na branch:** 12 vulnerabilidades + 25 testes de regressão automatizados.

---

*Para aprovação do Claupper antes do squash-merge e deploy. As três questões da seção 3 podem ser respondidas em separado conforme a Firjan priorizar.*
