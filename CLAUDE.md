# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository identity

This is a **fork of [sleede/fab-manager](https://github.com/sleede/fab-manager)** maintained for the **Firjan** Fab Lab installation since 2018. Two git remotes are configured:

- `origin` → `alexcvcoelho/fab-manager` (this fork — Firjan customizations live here)
- `upstream` → `sleede/fab-manager` (canonical open-source project)

Local `master` tracks `upstream/master`; `origin/master` carries the Firjan deviations. Feature branches (`feat/firjan-*`, `feature/getnet`, `feature/new-infos`, `feature/opensearch`, `feature/pagseguro*`) are based off `origin/master`. When proposing changes, target `origin` and the relevant `feat*`/`feature*` branch — never push customizations to `upstream`.

Upstream documentation lives at https://github.com/sleede/fab-manager/tree/master/doc and is the authoritative reference for behaviour that has **not** been customized.

## Stack (current — diverges from upstream docs)

The upstream `doc/architecture.md` still mentions Ruby 2.6 / Rails 5.2; this fork is on:

- **Ruby 3.2.2** (`.ruby-version`, `.tool-versions`)
- **Rails 7.0** (`Gemfile`)
- **Puma 6.1.0**, **Sidekiq ≥ 6.0.7**, **Shakapacker 6.6.0**
- **Node 18.15** / **Yarn 1**
- **PostgreSQL** (`pg`, `pg_search`), **Redis** (sessions + Sidekiq), **Elasticsearch 5** clients (`elasticsearch-rails ~> 5`)
- **Frontend:** Angular.js 1.8 + React 17 + TypeScript via `react2angular`. New code goes under `app/frontend/src/javascript/{components,api,models,hooks,lib}` (TS); legacy under `controllers/directives/services/filters` (JS, Angular).
- **Error reporting:** Sentry (`sentry-rails`)
- Fab-manager `version` in `package.json` reflects upstream release the fork is rebased on (currently `6.0.3`).

## Common commands

All Rails commands run via `bin/rails` / `bundle exec`. Frontend via `yarn`/`npm`.

```bash
# Frontend
yarn install
npm run lint                 # ESLint over app/frontend/src
npm test                     # Jest — roots: test/frontend, jsdom env
npm test -- path/to/file     # single test file (Jest CLI flags pass through)

# Backend (development)
bundle install
bin/rails db:setup           # create + migrate + seed (uses ADMIN_EMAIL / ADMIN_PASSWORD)
foreman start                # boots web (puma), worker (sidekiq), webpack dev-server per Procfile
bin/rails s                  # web only

# Backend tests — DO NOT use `rails test` directly
scripts/tests.sh                     # canonical runner — wires STRIPE_*, OAUTH_*, OIDC_* envs
scripts/tests.sh test/path/to/file   # forwards args to `rails test`
```

`scripts/tests.sh` will prompt interactively for any missing Stripe/OAuth/OIDC keys — set them in `.env` to avoid prompts. MiniTest is the framework (no RSpec).

## Production / Docker

- `Dockerfile` is **forked from upstream** with significant customization: supervisor as PID 1 instead of separate Sidekiq/Rails containers, openssh-server enabled (Azure deployment over SSH — see commit `d2f2cf52b`), and persistent volume mounts symlinked through `/usr/src/volume2/*`.
- `scripts/run.sh` opens a Rails console inside the running container by reading the service name out of `docker-compose.yml`.
- Other deploy/maintenance scripts in `scripts/`: `pg-analyzers.sh`, `postgre-upgrade.sh`, `redis-upgrade.sh`, `elastic-upgrade.sh`, `mount-*.sh`, `cve-2021-44228.sh`.

## Architecture — what this fork adds on top of upstream

The upstream Fab-manager domain (Availabilities → Slots → SlotsReservation → Reservation, with Machine/Space/Training/Event resources) is unchanged. The Firjan customizations layer in:

### Brazilian payment gateways
`app/services/payments/` holds one service per gateway, all sharing `payment_concern.rb`:

- `stripe_service.rb`, `payzen_service.rb` — upstream gateways
- `getnet_service.rb` — **custom**, Getnet (Santander) integration, full flow: auth → tokenize card → transaction → confirm. Frontend lives alongside in dedicated views/components; routes: `POST /api/getnet/{sdk_test,token_card,create_payment,confirm_payment}` (`config/routes.rb`).
- `pagseguro_service.rb` — **custom**, PagSeguro integration. Routes: `POST /api/pagseguro/{test_token,create_payment_link,notify}`. The `notify` endpoint is a webhook from PagSeguro — never authenticate as a user.
- `local_service.rb` — manual/offline payment

When touching payment flow, check **all** active gateways: Firjan toggles between them via the admin UI and changes in shared code (cart, invoices, payment schedules) must keep every gateway working.

### Brazilian-specific data
- `BrazillianDataService` (note the double-`l` typo, kept for compatibility) wraps the IBGE public API for Brazilian states (`/estados`), municipalities (`/municipios`), and a CEP lookup. Routes under `/api/brazillian_data/*`.
- **CPF validation** (Brazilian national ID) is part of the user profile — see commits around `9e2432b48 feat: cpf validation` and the profile completion flow.
- **Profile completion flow** — additional required fields beyond upstream; users are routed through completion before booking.

### Reports & exports
The current branch (`feat/firjan-report`) and recent commits add Firjan-specific Excel/CSV output: extra columns on member exports, reservable exports, wallet info on reports, GTM tracking. Customizations live in `app/services/excel_service.rb`, `availabilities_export_service.rb`, `members/list_service.rb`, `statistics_export_service.rb`. When upstream changes export shape, check that the Firjan-specific columns survived the rebase.

### Domain renames
Some upstream concepts are relabeled in the UI for Firjan (e.g. **"Space" → "Mentor"** per commit `e6d9707f7`). The model/table names stay upstream; only translations and labels change. Look in `config/locales/` (Crowdin-managed) before assuming a UI string maps to a model name.

### Reserved namespace
`app/services/firjan/` exists as an empty placeholder. New, **purely Firjan-specific** services should be added here to keep the diff against upstream localized and reduce rebase pain — do not put Firjan-only logic into upstream-shared services if a clean wrapper is possible.

## Code style and quality

- **Ruby:** Rubocop (`rubocop` + `rubocop-rails`) — config in `.rubocop.yml`. Run via `bundle exec rubocop`.
- **JS/TS:** ESLint with `eslint-plugin-fabmanager` and `eslint-config-standard`. Run via `npm run lint`.
- **Git hooks:** `overcommit` (`.overcommit.yml`) — installed via `bundle exec overcommit --install`.
- Migrations in `db/migrate/` follow upstream's monotonic-timestamp convention. **Never rebase or rename merged migrations** — production has already run them.

## When implementing new tasks

1. Check the upstream doc URL for that subsystem before changing it (memory has the index): a behaviour assumed to be Firjan-specific may already be configurable upstream via env var or admin setting.
2. Default to **edit existing services** rather than creating new ones; only add to `app/services/firjan/` when the logic is genuinely Firjan-only with no upstream analogue.
3. For new payment gateways or report fields, mirror the existing Getnet/PagSeguro patterns — don't invent a new structure.
4. Update locales in `config/locales/app.pt-BR.yml` (and `app.en.yml` to keep Crowdin happy) when adding user-facing strings; do not hardcode pt-BR strings in views or components.

## DBeaver MCP — read-only production database access

The project is configured (`.mcp.json`, gitignored) with the `dbeaver-mcp-server` MCP pointing at the DBeaver workspace at `C:\Program Files\DBeaver\workspace`. Use the **`Fabmanager Prd`** connection to query the `fablab_production` database.

**Hard rule: SELECT-only.** This database serves real members of the Firjan Fab Lab and contains LGPD-protected PII (CPF, RG, mother's name, address, IP). The MCP is started with `DBEAVER_READ_ONLY=true` and `.mcp.json` is gitignored to keep config per-developer.

- **Allowed:** `SELECT`, `EXPLAIN`, `SHOW`, `\d`/`\dt` style introspection.
- **Forbidden:** `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `DROP`, `CREATE`, `ALTER`, `GRANT`, `REVOKE`, `COPY ... FROM`, function definitions, anything DDL/DML.
- **No bulk dumps.** Limit queries (`LIMIT 100`); never export the full `users`/`profiles`/`invoicing_profiles` tables.
- **PII handling:** if a query returns a member's CPF/RG/mother_name/address/IP, treat the result as confidential — never echo it back into a commit message, code comment, log file, or generated doc. When you must reference a member in writing, use the **id** only.

If a workflow needs writes (corrections, cleanups), do it in DBeaver Desktop GUI manually with full review, never through the MCP.
