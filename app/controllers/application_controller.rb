# frozen_string_literal: true

# Main controller for the backend application. All controllers inherits from it
class ApplicationController < ActionController::Base
  include Pundit
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  after_action :set_csrf_cookie

  respond_to :html, :json

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :validate_session_fingerprint, if: :user_signed_in?
  around_action :switch_locale

  # Globally rescue Authorization Errors in controller.
  # Returning 403 Forbidden if permission is denied
  rescue_from Pundit::NotAuthorizedError, with: :permission_denied

  # Q2c in doc/security/resposta-claupper-2026-05-17.md: bind the session
  # to the caller's IP /24 subnet + User-Agent at sign-in time. If the
  # cookie is reused from a different network or with a different UA
  # (the scenario Rhamadan exercised in the 2026-05-14 print), the
  # session is dropped and the caller is forced to re-authenticate.
  #
  # The fingerprint is captured on the first authenticated request of
  # each session — `validate_session_fingerprint` writes it when absent.
  # Subsequent requests must match. The trade-off accepted by Claupper:
  # mobile users moving between networks (e.g. 4G → home WiFi crossing a
  # /24 boundary) will need to log in again.
  #
  # Operational override: set `SKIP_SESSION_FINGERPRINT=true` in the
  # container env to **downgrade** the check to UA-only (drop the IP
  # component). Used when the production reverse-proxy chain makes
  # `request.remote_ip` unstable (Azure App Service load balancer
  # rotating between requests of the same session) — in that scenario
  # every admin request would otherwise 401.
  #
  # When the flag is ON, the fingerprint still binds the session to the
  # User-Agent, so a cookie replayed via `curl` from the attacker's
  # machine is still rejected. What's lost: the cross-network defense
  # (same UA from a different IP no longer trips the check).
  #
  # We use a separate session key per regime so flipping the flag in
  # either direction does NOT invalidate existing sessions — each
  # regime seeds and validates its own key on the first request after
  # the flip. The session cookie's 8h absolute window (session_store.rb)
  # and Devise's 1h inactivity timeout still apply in both modes.
  SESSION_FINGERPRINT_KEY = :_session_fp        # IP/24 + UA (strict mode)
  SESSION_FINGERPRINT_KEY_UA = :_session_fp_ua  # UA-only (rollback mode)

  def index; end

  def sso_redirect
    @authorization_token = request.query_parameters[:auth_token]
    @authentication_token = form_authenticity_token
    @active_provider = AuthProvider.active
  end

  protected

  def set_csrf_cookie
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def verified_request?
    super || valid_authenticity_token?(session, request.headers['X-XSRF-TOKEN'])
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: [
                                        {
                                          profile_attributes: %i[phone last_name first_name cpf interest software_mastered social_name
                                                                 origin_state origin_city zipcode street neighborhood number complement city state rg rg_date_emission rg_issuing_organization rg_issuing_state mother_name occupational_status education_level financial_responsible_name financial_responsible_cpf],
                                          invoicing_profile_attributes: [
                                            organization_attributes: [:name, { address_attributes: [:address] }],
                                            user_profile_custom_fields_attributes: %i[profile_custom_field_id value],
                                            address_attributes: [:address]
                                          ],
                                          statistic_profile_attributes: %i[gender birthday]
                                        },
                                        :username, :is_allow_contact, :is_allow_newsletter, :cgu, :group_id
                                      ])
  end

  def default_url_options
    {
      host: Rails.application.secrets.default_host,
      protocol: Rails.application.secrets.default_protocol
    }
  end

  def permission_denied
    head :forbidden
  end

  # Set the configured locale for each action (API call)
  # @see https://guides.rubyonrails.org/i18n.html
  def switch_locale(&)
    locale = params[:locale] || Rails.application.secrets.rails_locale
    I18n.with_locale(locale, &)
  end

  # @return [User]
  # This is a placeholder for Devise's current_user.
  # As Devise generate the method at runtime, IDEs autocomplete features will complain about 'method not found'
  def current_user
    super
  end

  # This is a placeholder for Devise's authenticate_user! method.
  def authenticate_user!
    super
  end

  # N+1 query detection (https://github.com/flyerhzm/bullet)
  def skip_bullet
    previous_value = Bullet.enable?
    Bullet.enable = false
    yield
  ensure
    Bullet.enable = previous_value
  end

  private

  def validate_session_fingerprint
    key, current = if session_fingerprint_ip_disabled?
                     [SESSION_FINGERPRINT_KEY_UA, compute_session_fingerprint_ua_only]
                   else
                     [SESSION_FINGERPRINT_KEY, compute_session_fingerprint]
                   end

    expected = session[key]

    if expected.blank?
      # First request under the current regime — record the fingerprint.
      session[key] = current
      return
    end

    return if expected == current

    # Mismatch under the current regime: cookie was likely captured and
    # replayed elsewhere. Sign the user out and clear the session.
    sign_out current_user if respond_to?(:sign_out)
    reset_session
    respond_to do |format|
      format.json { render json: { error: 'Session fingerprint mismatch' }, status: :unauthorized and return }
      format.html { redirect_to '/users/sign_in' and return }
      format.any  { head :unauthorized and return }
    end
  end

  # Truthy values for SKIP_SESSION_FINGERPRINT: "true", "1", "yes".
  # Anything else (including unset) keeps the strict (IP/24 + UA) mode.
  # When truthy, only the UA component is used to bind the session.
  def session_fingerprint_ip_disabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('SKIP_SESSION_FINGERPRINT', false))
  end

  def compute_session_fingerprint
    ip_part = ip_fingerprint_part(request.remote_ip.to_s)
    ua_part = request.user_agent.to_s
    Digest::SHA256.hexdigest("#{ip_part}|#{ua_part}")
  end

  # UA-only fingerprint used when SKIP_SESSION_FINGERPRINT is truthy.
  # Empty IP slot is kept in the digest input so the hash space is
  # disjoint from the strict-mode digest (defense against accidental
  # collisions on tiny inputs).
  def compute_session_fingerprint_ua_only
    Digest::SHA256.hexdigest("|#{request.user_agent}")
  end

  # IPv4: keep the first 3 octets (/24 subnet). IPv6: keep the first 4
  # hextets (/64 prefix). Anything that doesn't parse falls back to the
  # raw string so we still bind to *something*.
  def ip_fingerprint_part(raw_ip)
    ip = IPAddr.new(raw_ip)
    if ip.ipv4?
      raw_ip.split('.').first(3).join('.')
    else
      raw_ip.split(':').first(4).join(':')
    end
  rescue IPAddr::InvalidAddressError, ArgumentError
    raw_ip
  end
end
