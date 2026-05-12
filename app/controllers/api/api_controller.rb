# frozen_string_literal: true

# Base controller for the JSON API consumed by the SPA frontend.
#
# Security safety net (added 2026-05 as part of the IDOR audit — see
# doc/security/README.md):
#
# `verify_authorized` is an after_action provided by Pundit. It raises
# `Pundit::AuthorizationNotPerformedError` whenever an action completes
# without having called `authorize(...)` or `skip_authorization`. This
# converts "forgot to authorize" from a silent runtime hole into a loud
# test failure, which is how we catch the class of bug responsible for the
# `members#show` / `projects#show` IDORs reported by the Firjan pentest.
#
# Public catalog endpoints that legitimately serve to anonymous users
# (e.g. `events#show`, `machines#show`, `plans#show`) must either call
# `authorize :resource, :public_action?` against a permissive policy, or
# declare `skip_authorization` inside the action body. They must NOT call
# `skip_after_action :verify_authorized` at the class level — that
# disables the safety net for every action in the controller, including
# the ones that need it.
class API::APIController < ApplicationController
  after_action :verify_authorized, unless: :devise_controller?
end
