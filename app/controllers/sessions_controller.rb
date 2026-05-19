# frozen_string_literal: true

# Devise controller for handling client sessions
class SessionsController < Devise::SessionsController
  def new
    # `GET /users/sign_in.json` previously crashed with 500 (template missing
    # for the JSON format) — pentest 2026-05-17 item E in
    # doc/security/relatorio-2026-05-17.md. The HTML sign-in page is what
    # Devise expects to render here; JSON callers should be hitting POST
    # /users/sign_in.json instead. Return a clean 405 for any non-HTML
    # method/format on this action.
    if request.format.json?
      head :method_not_allowed
      return
    end

    active_provider = Rails.configuration.auth_provider
    if active_provider.providable_type == 'DatabaseProvider'
      super
    else
      redirect_post "/users/auth/#{active_provider.strategy_name}"
    end
  end

  # FIXME, Method DELETE is not allowed by Access-Control-Allow-Methods in preflight response.
  # def destroy
  #   active_provider = Rails.configuration.auth_provider
  #   if active_provider.providable_type == 'OpenIdConnectProvider'
  #     redirect_to "/users/auth/#{active_provider.strategy_name}/logout"
  #   else
  #     super
  #   end
  # end
end
