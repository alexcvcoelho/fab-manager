# Inventário IDOR — baseline

_Gerado por `doc/security/audit_idor_baseline.rb` em 2026-05-12 11:34._

Legenda das colunas por action:
- **authorize**: action chama `authorize` (Pundit) — `✓` sim, `✗` não
- **scope**: action chama `policy_scope` (filtra coleção) — `✓` sim, `—` n/a (não-coleção)
- **risco**: heurística — `🔴` action é `show/update/destroy` sem `authorize`; `🟡` coleção sem `policy_scope`; `🟢` parece coberto

> ⚠️ Análise estática. Não considera herança de filtros via includes/concerns. Casos suspeitos pedem verificação manual.

## `app/controllers/api/abuses_controller.rb`

**Classe:** `API::AbusesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `create` | ✗ | — | 🔴 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/accounting_exports_controller.rb`

**Classe:** `API::AccountingExportsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `export` | ✓ | — | 🟢 |

## `app/controllers/api/accounting_periods_controller.rb`

**Classe:** `API::AccountingPeriodsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `last_closing_end` | ✓ | — | 🟢 |
| `download_archive` | ✓ | — | 🟢 |

## `app/controllers/api/admins_controller.rb`

**Classe:** `API::AdminsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `create` | ✓ | — | 🟢 |
| `destroy` | ✗ | — | 🔴 |

## `app/controllers/api/age_ranges_controller.rb`

**Classe:** `API::AgeRangesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/analytics_controller.rb`

**Classe:** `API::AnalyticsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `data` | ✓ | — | 🟢 |

## `app/controllers/api/api_controller.rb`

**Classe:** `API::APIController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|

## `app/controllers/api/auth_providers_controller.rb`

**Classe:** `API::AuthProvidersController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✓ | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `strategy_name` | ✓ | — | 🟢 |
| `show` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `mapping_fields` | ✓ | — | 🟢 |
| `active` | ✓ | — | 🟢 |
| `send_code` | ✓ | — | 🟢 |

## `app/controllers/api/availabilities_controller.rb`

**Classe:** `API::AvailabilitiesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `public` | ✗ | — | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `machine` | ✗ | — | 🟡 |
| `trainings` | ✗ | — | 🟡 |
| `spaces` | ✗ | — | 🟡 |
| `reservations` | ✓ | — | 🟢 |
| `export_availabilities` | ✓ | — | 🟢 |
| `lock` | ✓ | — | 🟢 |

## `app/controllers/api/brazillian_data_controller.rb`

**Classe:** `API::BrazillianDataController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `all_states` | ✗ | — | 🟡 |
| `cities` | ✗ | — | 🟡 |
| `zipcode` | ✗ | — | 🟡 |

## `app/controllers/api/cart_controller.rb`

**Classe:** `API::CartController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `create` | ✓ | — | 🟢 |
| `create_item` | ✓ | — | 🟢 |
| `add_item` | ✓ | — | 🟢 |
| `remove_item` | ✓ | — | 🟢 |
| `set_quantity` | ✓ | — | 🟢 |
| `set_offer` | ✓ | — | 🟢 |
| `refresh_item` | ✓ | — | 🟢 |
| `validate` | ✓ | — | 🟢 |
| `set_customer` | ✓ | — | 🟢 |

## `app/controllers/api/categories_controller.rb`

**Classe:** `API::CategoriesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/checkout_controller.rb`

**Classe:** `API::CheckoutController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `payment` | ✓ | — | 🟢 |
| `confirm_payment` | ✓ | — | 🟢 |

## `app/controllers/api/components_controller.rb`

**Classe:** `API::ComponentsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/coupons_controller.rb`

**Classe:** `API::CouponsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `validate` | ✗ | — | 🟡 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `send_to` | ✓ | — | 🟢 |

## `app/controllers/api/credits_controller.rb`

**Classe:** `API::CreditsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `user_resource` | ✓ | — | 🟢 |

## `app/controllers/api/custom_assets_controller.rb`

**Classe:** `API::CustomAssetsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `update` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `show` | ✗ | — | 🔴 |

## `app/controllers/api/event_themes_controller.rb`

**Classe:** `API::EventThemesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/events_controller.rb`

**Classe:** `API::EventsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✓ | 🟢 |
| `upcoming` | ✗ | — | 🟡 |
| `show` | ✗ | — | 🔴 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/exports_controller.rb`

**Classe:** `API::ExportsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `download` | ✓ | — | 🟢 |
| `status` | ✓ | — | 🟢 |

## `app/controllers/api/files_controller.rb`

**Classe:** `API::FilesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `mime` | ✓ | — | 🟢 |

## `app/controllers/api/getnet_controller.rb`

**Classe:** `API::GetnetController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `sdk_test` | ✗ | — | 🟡 |
| `token_card` | ✗ | — | 🟡 |
| `create_payment` | ✗ | — | 🟡 |
| `confirm_payment` | ✗ | — | 🟡 |

## `app/controllers/api/groups_controller.rb`

**Classe:** `API::GroupsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/i_calendar_controller.rb`

**Classe:** `API::ICalendarController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `create` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `events` | ✗ | — | 🟡 |
| `sync` | ✗ | — | 🟡 |

## `app/controllers/api/imports_controller.rb`

**Classe:** `API::ImportsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `show` | ✓ | — | 🟢 |
| `members` | ✓ | — | 🟢 |

## `app/controllers/api/invoices_controller.rb`

**Classe:** `API::InvoicesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `show` | ✓ | — | 🟢 |
| `download` | ✓ | — | 🟢 |
| `list` | ✓ | ✗ | 🟢 |
| `create` | ✓ | — | 🟢 |
| `first` | ✓ | — | 🟢 |

## `app/controllers/api/licences_controller.rb`

**Classe:** `API::LicencesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/local_payment_controller.rb`

**Classe:** `API::LocalPaymentController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `confirm_payment` | ✓ | — | 🟢 |

## `app/controllers/api/machine_categories_controller.rb`

**Classe:** `API::MachineCategoriesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/machines_controller.rb`

**Classe:** `API::MachinesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✗ | — | 🔴 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/members_controller.rb`

**Classe:** `API::MembersController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✓ | 🟢 |
| `last_subscribed` | ✗ | — | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `export_subscriptions` | ✓ | — | 🟢 |
| `export_reservations` | ✓ | — | 🟢 |
| `export_members` | ✓ | — | 🟢 |
| `merge` | ✓ | — | 🟢 |
| `list` | ✓ | ✗ | 🟢 |
| `search` | ✗ | ✗ | 🟡 |
| `mapping` | ✓ | — | 🟢 |
| `complete_tour` | ✓ | — | 🟢 |
| `update_role` | ✓ | — | 🟢 |
| `current` | ✓ | — | 🟢 |
| `validate` | ✓ | — | 🟢 |

## `app/controllers/api/notification_preferences_controller.rb`

**Classe:** `API::NotificationPreferencesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `update` | ✓ | — | 🟢 |
| `bulk_update` | ✓ | — | 🟢 |

## `app/controllers/api/notification_types_controller.rb`

**Classe:** `API::NotificationTypesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/api/notifications_controller.rb`

**Classe:** `API::NotificationsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `last_unread` | ✗ | — | 🟡 |
| `polling` | ✗ | — | 🟡 |
| `update` | ✗ | — | 🔴 |
| `update_all` | ✗ | — | 🟡 |

## `app/controllers/api/open_api_clients_controller.rb`

**Classe:** `API::OpenAPIClientsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `reset_token` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/openlab_projects_controller.rb`

**Classe:** `API::OpenlabProjectsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/api/orders_controller.rb`

**Classe:** `API::OrdersController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `withdrawal_instructions` | ✓ | — | 🟢 |

## `app/controllers/api/pagseguro_controller.rb`

**Classe:** `API::PagseguroController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `test_token` | ✗ | — | 🟡 |
| `create_payment_link` | ✗ | — | 🟡 |
| `notify` | ✗ | — | 🟡 |
| `on_payment_success` | ✗ | — | 🟡 |

## `app/controllers/api/payment_schedules_controller.rb`

**Classe:** `API::PaymentSchedulesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `list` | ✓ | ✗ | 🟢 |
| `download` | ✓ | — | 🟢 |
| `cash_check` | ✓ | — | 🟢 |
| `confirm_transfer` | ✓ | — | 🟢 |
| `refresh_item` | ✓ | — | 🟢 |
| `pay_item` | ✓ | — | 🟢 |
| `show_item` | ✓ | — | 🟢 |
| `cancel` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |

## `app/controllers/api/payments_controller.rb`

**Classe:** `API::PaymentsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `confirm_payment` | ✗ | — | 🟡 |

## `app/controllers/api/payzen_controller.rb`

**Classe:** `API::PayzenController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `sdk_test` | ✗ | — | 🟡 |
| `create_payment` | ✗ | — | 🟡 |
| `create_token` | ✗ | — | 🟡 |
| `update_token` | ✗ | — | 🟡 |
| `check_cart` | ✗ | — | 🟡 |
| `check_hash` | ✗ | — | 🟡 |
| `confirm_payment` | ✗ | — | 🟡 |
| `confirm_payment_schedule` | ✗ | — | 🟡 |

## `app/controllers/api/plan_categories_controller.rb`

**Classe:** `API::PlanCategoriesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/plans_controller.rb`

**Classe:** `API::PlansController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✗ | — | 🔴 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `durations` | ✗ | — | 🟡 |

## `app/controllers/api/prepaid_packs_controller.rb`

**Classe:** `API::PrepaidPacksController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/price_categories_controller.rb`

**Classe:** `API::PriceCategoriesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `update` | ✓ | — | 🟢 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/prices_controller.rb`

**Classe:** `API::PricesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `create` | ✓ | — | 🟢 |
| `index` | ✗ | ✗ | 🟡 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `compute` | ✗ | — | 🟡 |

## `app/controllers/api/pricing_controller.rb`

**Classe:** `API::PricingController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `update` | ✓ | — | 🟢 |

## `app/controllers/api/product_categories_controller.rb`

**Classe:** `API::ProductCategoriesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✗ | — | 🔴 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `position` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/products_controller.rb`

**Classe:** `API::ProductsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✗ | — | 🔴 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `clone` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `stock_movements` | ✓ | — | 🟢 |

## `app/controllers/api/profile_custom_fields_controller.rb`

**Classe:** `API::ProfileCustomFieldsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/projects_controller.rb`

**Classe:** `API::ProjectsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✓ | 🟢 |
| `last_published` | ✗ | — | 🟡 |
| `show` | ✗ | — | 🔴 |
| `create` | ✗ | — | 🔴 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `collaborator_valid` | ✗ | — | 🟡 |
| `search` | ✗ | ✗ | 🟡 |

## `app/controllers/api/reservations_controller.rb`

**Classe:** `API::ReservationsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |

## `app/controllers/api/settings_controller.rb`

**Classe:** `API::SettingsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✓ | 🟢 |
| `update` | ✓ | — | 🟢 |
| `bulk_update` | ✓ | — | 🟢 |
| `show` | ✓ | — | 🟢 |
| `test_present` | ✓ | — | 🟢 |
| `reset` | ✓ | — | 🟢 |

## `app/controllers/api/slots_reservations_controller.rb`

**Classe:** `API::SlotsReservationsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `update` | ✓ | — | 🟢 |
| `cancel` | ✓ | — | 🟢 |

## `app/controllers/api/spaces_controller.rb`

**Classe:** `API::SpacesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✗ | — | 🔴 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/statistics_controller.rb`

**Classe:** `API::StatisticsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `export_` | ✓ | — | 🟢 |
| `export_global` | ✓ | — | 🟢 |
| `scroll` | ✓ | — | 🟢 |

## `app/controllers/api/statuses_controller.rb`

**Classe:** `API::StatusesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/stripe_controller.rb`

**Classe:** `API::StripeController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `confirm_payment` | ✗ | — | 🟡 |
| `online_payment_status` | ✓ | — | 🟢 |
| `setup_intent` | ✗ | — | 🟡 |
| `setup_subscription` | ✗ | — | 🟡 |
| `confirm_subscription` | ✗ | — | 🟡 |
| `update_card` | ✗ | — | 🟡 |

## `app/controllers/api/stylesheets_controller.rb`

**Classe:** `API::StylesheetsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `show` | ✗ | — | 🔴 |

## `app/controllers/api/subscriptions_controller.rb`

**Classe:** `API::SubscriptionsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `show` | ✓ | — | 🟢 |
| `payment_details` | ✓ | — | 🟢 |
| `cancel` | ✓ | — | 🟢 |

## `app/controllers/api/supporting_document_files_controller.rb`

**Classe:** `API::SupportingDocumentFilesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `update` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `download` | ✓ | — | 🟢 |
| `show` | ✗ | — | 🔴 |

## `app/controllers/api/supporting_document_refusals_controller.rb`

**Classe:** `API::SupportingDocumentRefusalsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |

## `app/controllers/api/supporting_document_types_controller.rb`

**Classe:** `API::SupportingDocumentTypesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/tags_controller.rb`

**Classe:** `API::TagsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/themes_controller.rb`

**Classe:** `API::ThemesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✓ | — | 🟢 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/trainings_controller.rb`

**Classe:** `API::TrainingsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✗ | — | 🔴 |
| `create` | ✓ | — | 🟢 |
| `update` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |
| `availabilities` | ✓ | — | 🟢 |

## `app/controllers/api/trainings_pricings_controller.rb`

**Classe:** `API::TrainingsPricingsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `update` | ✗ | — | 🔴 |
| `trainings_pricing_params` | ✗ | — | 🟡 |

## `app/controllers/api/translations_controller.rb`

**Classe:** `API::TranslationsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `show` | ✗ | — | 🔴 |

## `app/controllers/api/user_packs_controller.rb`

**Classe:** `API::UserPacksController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/api/users_controller.rb`

**Classe:** `API::UsersController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✓ | ✗ | 🟢 |
| `create` | ✓ | — | 🟢 |
| `destroy` | ✓ | — | 🟢 |

## `app/controllers/api/version_controller.rb`

**Classe:** `API::VersionController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `show` | ✓ | — | 🟢 |

## `app/controllers/api/wallet_controller.rb`

**Classe:** `API::WalletController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `by_user` | ✓ | — | 🟢 |
| `transactions` | ✓ | — | 🟢 |
| `credit` | ✓ | — | 🟢 |

## `app/controllers/open_api/v1/accounting_controller.rb`

**Classe:** `OpenAPI::V1::AccountingController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/availabilities_controller.rb`

**Classe:** `OpenAPI::V1::AvailabilitiesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/base_controller.rb`

**Classe:** `OpenAPI::V1::BaseController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|

## `app/controllers/open_api/v1/bookable_machines_controller.rb`

**Classe:** `OpenAPI::V1::BookableMachinesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/events_controller.rb`

**Classe:** `OpenAPI::V1::EventsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/invoices_controller.rb`

**Classe:** `OpenAPI::V1::InvoicesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `download` | ✗ | — | 🟡 |

## `app/controllers/open_api/v1/machines_controller.rb`

**Classe:** `OpenAPI::V1::MachinesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `create` | ✗ | — | 🔴 |
| `update` | ✗ | — | 🔴 |
| `show` | ✗ | — | 🔴 |
| `destroy` | ✗ | — | 🔴 |

## `app/controllers/open_api/v1/plan_categories_controller.rb`

**Classe:** `OpenAPI::V1::PlanCategoriesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/plans_controller.rb`

**Classe:** `OpenAPI::V1::PlansController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✗ | — | 🔴 |

## `app/controllers/open_api/v1/prices_controller.rb`

**Classe:** `OpenAPI::V1::PricesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/reservations_controller.rb`

**Classe:** `OpenAPI::V1::ReservationsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/spaces_controller.rb`

**Classe:** `OpenAPI::V1::SpacesController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |
| `show` | ✗ | — | 🔴 |

## `app/controllers/open_api/v1/subscriptions_controller.rb`

**Classe:** `OpenAPI::V1::SubscriptionsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/trainings_controller.rb`

**Classe:** `OpenAPI::V1::TrainingsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/user_trainings_controller.rb`

**Classe:** `OpenAPI::V1::UserTrainingsController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## `app/controllers/open_api/v1/users_controller.rb`

**Classe:** `OpenAPI::V1::UsersController`  
**Auth baseline:** ⚠️ none

| Action | authorize | scope | risco |
|--------|-----------|-------|-------|
| `index` | ✗ | ✗ | 🟡 |

## Resumo

- Controllers analisados: **88**
- Actions totais (públicas): **341**
- Actions `show/update/destroy/create` sem `authorize`: **23** 🔴
- Coleções (`index/list/search`) sem `policy_scope` nem `authorize`: **53** 🟡

---

# Análise de policies

Heurística: o `UserPolicy#show?` (vetor confirmado por Claupper) libera leitura quando `record.is_allow_contact && record.member?` é verdadeiro — não checa posse nem role admin/manager. Esta seção procura padrões similares.

Sinais:
- `🟢 valida posse + role`: corpo referencia `user.id == record.id` (ou equivalente) E também `user.admin?`/`user.manager?`/`user.privileged?`
- `🟡 só role`: só checagem de role (suficiente para recursos administrativos puros)
- `🟡 só posse`: só checagem de posse (suficiente para "current user resources")
- `🔴 nenhuma checagem clara` ou `retorna true`: corpo não referencia nem posse nem role — candidato a IDOR
- `🔵 revisar cláusulas OR`: 🟢 estruturalmente mas com 2+ `||` em `show?`/`update?`/etc. — qualquer cláusula adicional pode bypassar (é o padrão do `UserPolicy#show?`)

> ⚠️ Heurística simples. Resultado 🔴 não é prova de vulnerabilidade — pode haver lógica equivalente expressa de outro jeito. Mas todo 🔴 merece revisão manual.

## `app/policies/abuse_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `index?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin?` |

## `app/policies/accounting_export_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `export?` | 🟡 só role | `user.admin?` |

## `app/policies/accounting_period_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `last_closing_end?` | 🟡 só role | `user.admin? || user.manager?` |

## `app/policies/admin_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `index?` | 🟡 só role | `user.admin? || user.manager?` |
| `create?` | 🟡 só role | `user.admin?` |

## `app/policies/analytics_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `data?` | 🟡 só role | `user.admin?` |

## `app/policies/auth_provider_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `active?` | 🔴 nenhuma checagem clara | `user` |
| `send_code?` | 🔴 nenhuma checagem clara | `user` |

## `app/policies/availability_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `export?` | 🟡 só role | `user.admin?` |

## `app/policies/cart_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `!Setting.get('store_hidden') || user&.privileged?` |
| `set_offer?` | 🟡 só role | `!record.is_offered || (user.privileged? && record.customer_id != user.id)` |
| `set_customer?` | 🟡 só role | `user.privileged?` |

## `app/policies/component_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `create? (alias de `create?`)` |
| `destroy?` | 🟡 só role | `create? (alias de `create?`)` |

## `app/policies/credit_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `index?` | 🟡 só role | `user.admin?` |
| `create?` | 🟡 só role | `index? (alias de `index?`)` |
| `update?` | 🟡 só role | `index? (alias de `index?`)` |
| `destroy?` | 🟡 só role | `index? (alias de `index?`)` |
| `user_resource?` | 🟡 só posse | `record.id == user.id` |

## `app/policies/custom_asset_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |

## `app/policies/event_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin? || user.manager?` |
| `update?` | 🟡 só role | `create? (alias de `create?`)` |
| `destroy?` | 🟡 só role | `create? (alias de `create?`)` |

## `app/policies/file_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `mime?` | 🟡 só role | `user.admin?` |

## `app/policies/group_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin? && record.destroyable?` |

## `app/policies/i_calendar_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin? || user.manager?` |
| `destroy?` | 🟡 só role | `user.admin? || user.manager?` |

## `app/policies/import_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `show?` | 🟡 só role | `user.admin?` |
| `members?` | 🟡 só role | `user.admin?` |

## `app/policies/invoice_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `index?` | 🟡 só role | `user.admin?` |
| `download?` | 🟢 valida posse + role | `user.admin? || user.manager? || (record.invoicing_profile.user_id == user.id)` |
| `create?` | 🟡 só role | `user.admin? || user.manager?` |
| `list?` | 🟡 só role | `user.admin? || user.manager?` |
| `first?` | 🟡 só role | `user.admin?` |

## `app/policies/licence_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `create? (alias de `create?`)` |
| `destroy?` | 🟡 só role | `create? (alias de `create?`)` |

## `app/policies/local_payment_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `confirm_payment?` | 🟡 só role | `# only admins and managers can offer free extensions of a subscription` |

## `app/policies/machine_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin?` |

## `app/policies/notification_preference_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `update?` | 🟡 só role | `user.admin?` |
| `bulk_update?` | 🟡 só role | `user.admin?` |

## `app/policies/open_api/client_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `index?` | 🟡 só role | `user.has_role? :admin` |
| `create?` | 🟡 só role | `user.has_role? :admin` |
| `update?` | 🟡 só role | `user.has_role? :admin` |
| `reset_token?` | 🟡 só role | `user.has_role? :admin` |
| `destroy?` | 🟡 só role | `user.has_role? :admin and record.calls_count == 0` |

## `app/policies/order_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `show?` | 🟢 valida posse + role | `user.privileged? || (record.statistic_profile_id == user.statistic_profile.id)` |
| `update?` | 🟡 só role | `user.privileged?` |
| `destroy?` | 🟡 só role | `user.privileged?` |
| `withdrawal_instructions?` | 🟢 valida posse + role | `user&.privileged? || (record&.statistic_profile_id == user&.statistic_profile&.i` |

## `app/policies/partner_plan_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `index?` | 🟡 só role | `user.admin?` |
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin? and record.destroyable?` |

## `app/policies/payment_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `online_payment_status?` | 🟡 só role | `user.admin? || user.manager?` |

## `app/policies/payzen_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `sdk_test?` | 🟡 só role | `user.admin?` |

## `app/policies/plan_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin? and record.destroyable?` |

## `app/policies/prepaid_pack_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin? && record.destroyable?` |

## `app/policies/price_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin? && record.duration != 60` |
| `destroy?` | 🟡 só role | `user.admin? && record.duration != 60` |
| `update?` | 🟡 só role | `user.admin?` |

## `app/policies/pricing_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `update?` | 🟡 só role | `user.admin?` |

## `app/policies/product_category_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.privileged?` |
| `update?` | 🟡 só role | `user.privileged?` |
| `destroy?` | 🟡 só role | `user.privileged?` |
| `position?` | 🟡 só role | `user.privileged?` |

## `app/policies/product_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.privileged?` |
| `update?` | 🟡 só role | `user.privileged?` |
| `clone?` | 🟡 só role | `user.privileged?` |
| `destroy?` | 🟡 só role | `user.privileged?` |
| `stock_movements?` | 🟡 só role | `user.privileged?` |

## `app/policies/profile_custom_field_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin?` |

## `app/policies/project_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `update?` | 🟢 valida posse + role | `user.admin? or record.author.user_id == user.id or record.users.include?(user)` |
| `destroy?` | 🟢 valida posse + role | `user.admin? or record.author.user_id == user.id` |

## `app/policies/reservation_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin? || (user.manager? && record.user_id != user.id) || record.price.zero` |
| `update?` | 🔵 revisar cláusulas OR | `user.admin? || user.manager? || record.user == user` |

## `app/policies/setting_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `show?` | 🟡 só role | `user&.admin? || SettingPolicy.public_whitelist.include?(record.name)` |
| `test_present?` | 🟡 só role | `user&.admin? || SettingPolicy.public_whitelist.concat(%w[openlab_app_secret stri` |

## `app/policies/slots_reservation_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `update?` | 🟡 só role | `# check that the update is allowed and the prevention delay has not expired` |
| `cancel?` | 🟡 só role | `user.admin? || user.manager? || record.reservation.user == user` |

## `app/policies/space_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin?` |

## `app/policies/status_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `create? (alias de `create?`)` |
| `destroy?` | 🟡 só role | `create? (alias de `create?`)` |

## `app/policies/subscription_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `show?` | 🟡 só role | `user.admin? || user.manager? || record.user.id == user.id` |
| `payment_details?` | 🟡 só role | `user.admin? || user.manager?` |
| `cancel?` | 🟡 só role | `user.admin? || user.manager?` |

## `app/policies/supporting_document_file_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `index?` | 🟡 só role | `user.privileged?` |
| `create?` | 🟢 valida posse + role | `user.privileged? or record.user_id == user.id` |
| `update?` | 🟢 valida posse + role | `user.privileged? or record.user_id == user.id` |
| `download?` | 🟢 valida posse + role | `user.privileged? or record.user_id == user.id` |

## `app/policies/supporting_document_refusal_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `index?` | 🟡 só role | `user.privileged?` |
| `create?` | 🟡 só role | `user.privileged?` |
| `show?` | 🟡 só role | `user.privileged?` |

## `app/policies/supporting_document_type_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin?` |
| `destroy?` | 🟡 só role | `user.admin?` |

## `app/policies/tag_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `create? (alias de `create?`)` |
| `destroy?` | 🟡 só role | `create? (alias de `create?`)` |

## `app/policies/theme_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `create? (alias de `create?`)` |
| `destroy?` | 🟡 só role | `create? (alias de `create?`)` |

## `app/policies/training_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `create?` | 🟡 só role | `user.admin?` |
| `update?` | 🟡 só role | `user.admin? || user.manager?` |
| `destroy?` | 🟡 só role | `user.admin? && record.destroyable?` |
| `availabilities?` | 🟡 só role | `user.admin? || user.manager?` |

## `app/policies/user_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `show?` | 🔵 revisar cláusulas OR | `user.admin? || user.manager? || (record.is_allow_contact && record.member?) || (` |
| `current?` | 🟢 valida posse + role | `user.admin? || user.manager? || (user.id == record.id)` |
| `update?` | 🔵 revisar cláusulas OR | `user.admin? || user.manager? || (user.id == record.id)` |
| `destroy?` | 🟢 valida posse + role | `user.admin? || (user.id == record.id)` |

## `app/policies/version_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `show?` | 🟡 só role | `user.admin?` |

## `app/policies/wallet_policy.rb`

| Predicate | Risco | Primeira linha |
|-----------|-------|----------------|
| `credit?` | 🟡 só role | `user.admin? || (user.manager? && user != record.user)` |

## Resumo de policies

- Policies analisadas: **67**
- Predicates 🔴 (sem checagem clara de posse nem role): **2**
- Predicates 🔵 (estruturalmente ok mas com cláusulas OR a revisar manualmente): **3**
