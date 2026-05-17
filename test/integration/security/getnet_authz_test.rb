# frozen_string_literal: true

require 'test_helper'

# Regression tests for the Getnet payment endpoints hardening — pentest
# 2026-05-17 (item #13 in doc/security/pentest-2026-05-17.md).
#
# Before this fix, `API::GetnetController` only required `authenticate_user!`.
# Any logged-in member could:
#
#   - call `/api/getnet/token_card` with an arbitrary `customer_id` to
#     tokenize a card under another user's identity, or to use the Firjan
#     Getnet credentials as a "card validation oracle"
#   - call `/api/getnet/create_payment` / `confirm_payment` without any
#     cart context, triggering NoMethodError stack traces
#
# Fix:
#   - `token_card`       : if `customer_id` is passed, it MUST match
#                          `current_user.id`; the Getnet payload always
#                          uses `current_user.id` regardless
#   - `create_payment` / : same customer enforcement + `cart_items` must
#     `confirm_payment`    be present (otherwise 422)
class GetnetAuthzTest < ActionDispatch::IntegrationTest
  setup do
    @member       = User.find(2) # jdupond
    @other_member = User.find(4) # kdumas
  end

  # ----- token_card ------------------------------------------------------------

  test 'member cannot tokenize a card under another user identity' do
    login_as(@member, scope: :user)
    post '/api/getnet/token_card',
         params: { card_number: '4111111111111111', customer_id: @other_member.id }.to_json,
         headers: default_headers
    assert_equal 403, response.status,
                 'customer_id != current_user.id must be rejected'
  end

  # ----- create_payment / confirm_payment --------------------------------------

  test 'create_payment without cart_items is rejected with 422 (not 500)' do
    login_as(@member, scope: :user)
    post '/api/getnet/create_payment', params: { customer_id: @member.id }.to_json, headers: default_headers
    assert_equal 422, response.status,
                 'missing cart_items must produce a clean 422, not a NoMethodError stack trace'
  end

  test 'create_payment with mismatched customer_id is rejected with 403' do
    login_as(@member, scope: :user)
    post '/api/getnet/create_payment',
         params: { customer_id: @other_member.id, cart_items: { items: [] } }.to_json,
         headers: default_headers
    assert_equal 403, response.status
  end

  test 'confirm_payment without cart_items is rejected with 422' do
    login_as(@member, scope: :user)
    post '/api/getnet/confirm_payment', params: { customer_id: @member.id }.to_json, headers: default_headers
    assert_equal 422, response.status
  end
end
