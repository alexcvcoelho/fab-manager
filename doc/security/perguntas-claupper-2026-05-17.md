# Perguntas pendentes para Claupper / Firjan — pós-pentest 2026-05-17

Os achados do Ramadan foram cruzados com as 3 rodadas de correção (v1/v2/v3 na branch `feat/firjan-security-idor-v2`). A maior parte foi fechada. **Os pontos abaixo dependem de decisões de produto ou de risco aceito** e estão paradas aguardando posicionamento.

---

## 1. Enumeração de membros via `/api/members/search/:query` (achado H)

**O que o Ramadan reportou:** member logado consegue chamar `GET /api/members/search/<substring>` (inclusive com chars encoded tipo `%60`, `%24`, ou apenas vogais isoladas) e receber lista de members com `id, name, group_id, validated_at` — efetivamente enumerando a base.

**Por que não foi fechado tecnicamente:** o endpoint `search` é usado pela **feature de adicionar colaboradores em projeto**. Restringir a admin/manager bloqueia esse fluxo legítimo.

**Pergunta para o Claupper:**

> A feature "adicionar colaborador ao projeto" usa hoje o endpoint `/api/members/search`. Esse fluxo é importante o suficiente para mantermos o search aberto a qualquer member logado (com o risco de enumeração que o Ramadan identificou)?
>
> **Opções:**
>
> **a)** Manter como está. Member encontra qualquer outro member pelo nome. Risco de enumeração aceito.
>
> **b)** Restringir search a admin/manager. A feature de colaboradores passa a depender de algum convite por email/link (mais trabalho, mas elimina a enumeração).
>
> **c)** Manter o search mas reduzir o que ele devolve para non-priv: só `id` e `name`, sem `group_id` nem `validated_at`. E exigir mínimo de 3 caracteres na query, sem aceitar `%encoded` ou wildcards (mitiga enumeração massiva mas mantém o fluxo).
>
> **d)** Substituir o "buscar e clicar" por "informar email/username exato" (sem listagem). Quem é colaborador é convidado por endereço direto.

**Recomendação técnica:** **c** é o equilíbrio melhor entre proteção e usabilidade. **d** é o mais defensivo. **a** documenta o risco como aceito formalmente.

---

## 2. Cookie de sessão sem device binding (achado C)

**O que o Ramadan reportou:** capturou o cookie `_Fab-manager_session` em um device e usou em outro, acessando `/api/members/current` como o user original.

**Estado técnico:** o cookie já tem `HttpOnly + Secure + SameSite=Lax` (correto). O que falta é **device binding** — vincular a sessão ao IP/UA do login. Sem isso, qualquer cookie exfiltrado vira takeover.

**Por que não foi fechado tecnicamente:** todas as opções têm trade-offs de UX que dependem de decisão de produto.

**Pergunta para o Claupper:**

> Qual abordagem para o risco de hijack via cookie roubado?
>
> **Opções:**
>
> **a) Não mexer** (status quo). Documentar como risco aceito. Detecção via Sentry/log de acessos suspeitos (se Sentry for ativado em produção).
>
> **b) Sessão de curta duração** (30min-2h) + re-autenticação por senha em ações sensíveis (trocar email/senha, fazer pagamento, excluir conta). Já está parcialmente implementado — o `current_password` é exigido em `PUT /api/members/:id`. Reduz a janela de exploração. Usuário pode reclamar de "ter que logar mais vezes" se navegar lento.
>
> **c) Bind por subnet IP /24** + User-Agent. Atacante na mesma rede ainda consegue, mas atacante remoto não. Membros mobile que mudam de 4G/WiFi geralmente ficam na mesma subnet — fricção baixa.
>
> **d) 2FA / MFA** (TOTP via Google Authenticator). Defesa real, mas 1-2 dias de implementação + comunicação aos members + suporte (recuperação de conta perdida etc.).
>
> **e) Combinação b + c**: sessão curta + bind subnet. Sem 2FA, é o setup mais defensivo possível.

**Recomendação técnica:** **b** sozinha já melhora muito. Se a Firjan considerar PII/financeiro como "alto valor", subir para **e**. **d** é o ideal mas o ROI depende da base de members aceitar.

---

## 3. `/api/translations/pt/app.admin` acessível a anônimo (achado G)

**O que o Ramadan reportou:** o endpoint público de traduções vaza os **labels** (textos da UI) da seção administrativa, incluindo nomes de campos de configuração dos gateways de pagamento: `payzen_password`, `client_secret`, `seller_id`, `pagseguro_token`, etc.

Não vaza **valores** (a string `"Senha"` aparece, não a senha real), mas expõe estrutura administrativa a anônimos.

**Por que não foi fechado tecnicamente:** o frontend Angular carrega traduções dinamicamente desse endpoint. Restringir o escopo `app.admin` a admin logado exige refatorar o frontend para esperar 401/403 e tratar.

**Pergunta para o Claupper:**

> O endpoint `/api/translations/:locale/:scope` retorna todas as strings i18n. Para o escopo `app.admin` (e talvez `app.shared.admin`), vale restringir a admin/manager logado, mesmo que o front precise de ajuste?
>
> **Opções:**
>
> **a)** Não mexer. Os labels expostos são apenas texto de UI; não vazam valores. Aceitar como risco baixo.
>
> **b)** Restringir o escopo `app.admin` a privileged users. O front carrega só o que precisa quando o user é admin/manager. Demanda ajuste do bootstrap do Angular.

**Recomendação técnica:** **a** se quiser fechar a sessão e priorizar coisas mais críticas. **b** é o jeito certo a médio prazo mas custa horas de ajuste no front.

---

## Achados encerrados nesta rodada (sem pendência)

Documentado pra referência:

| # | Achado | Conclusão |
|---|---|---|
| A | Dump de `/api/members` | Fechado v2 (`e29c3ec13`) |
| B | Dump de `/api/groups` com `users.count` | Fechado v2 (`92e8027e9`) |
| I | Enumeração `/api/orders?user_id=X` | **Falso positivo** — `OrderService#filter_by_user` faz silent fallback para o próprio user quando non-priv envia user_id alheio. Defesa já existe, só não retorna 403 explícito |
| E | `GET /users/sign_in.json` → 500 | Fechado nesta rodada (SessionsController#new agora retorna 405 explícito para JSON) |
| F | `POST /users/sign_in.json` `{user:{}}` → 201 | Comportamento estranho (Devise retorna 201 com user já logado), não é vulnerabilidade explorável. Documentado como noise. |
| D | `/api/settings?names=PAYLOAD<script>` aceita chars | Não reflete hoje, não é XSS reflected. Defense in depth aceita como pendência futura. |

---

*Documento para alinhamento com Claupper antes de fechar a Task 2 (maio/2026). Após decisão dele, atualizar este arquivo + abrir issues/branches conforme.*
