# frozen_string_literal: true

require 'test_helper'

# Regression tests for the authorization + data minimization layer around
# API::MembersController.
#
# Background: a pentest reported in 2026-03 that any authenticated user could
# read another member's full profile (CPF, RG, mother's name, address, IP) by
# changing the :id in `GET /api/members/:id`. The first round of fixes
# (UserPolicy#show? — phase 3a) closed the IDOR on `show`, but Firjan's
# security team reported in 2026-05 that the listing and `last_subscribed`
# endpoints continued to expose email/phone for any logged-in member.
# Round v2 applied upstream's fa5489ae6 patch adapted for the Firjan schema
# (CPF/RG/mother_name/address are also in the privileged-only block, and
# self is treated as non-restricted so a member can keep editing their own
# profile). See doc/security/README.md.
#
# These tests pin the corrected behavior so a future rebase that carries the
# original permissive predicates back fails the build instead of silently
# reopening the vulnerability.
class MembersAsMemberTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.find(2)        # jdupond, role: member, is_allow_contact: true
    @other_member = User.find(4)  # kdumas, role: member, is_allow_contact: true
    @admin = User.find(1)
    login_as(@member, scope: :user)
  end

  # ----- phase 3a regression — UserPolicy#show? --------------------------------

  test 'member cannot read another members full profile (IDOR regression)' do
    get "/api/members/#{@other_member.id}", headers: default_headers
    assert_equal 403, response.status,
                 "Member should not be able to read another member's profile via /api/members/:id"
    assert_empty response.body
  end

  test 'member can read own profile' do
    get "/api/members/#{@member.id}", headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    assert_equal @member.id, body[:id]
  end

  test 'admin can read any member profile' do
    logout(:user)
    login_as(@admin, scope: :user)
    get "/api/members/#{@other_member.id}", headers: default_headers
    assert_equal 200, response.status, response.body
  end

  test 'is_allow_contact flag does not grant read access to other members' do
    assert @other_member.is_allow_contact?,
           'precondition: target must have is_allow_contact=true for this test to exercise the regression'
    get "/api/members/#{@other_member.id}", headers: default_headers
    assert_equal 403, response.status,
                 'is_allow_contact must not influence read authorization (only the members directory listing)'
  end

  # ----- phase v2 — self sees own PII (must still work for the edit screen) ----

  test 'member sees own CPF and address on own profile (no over-restriction)' do
    get "/api/members/#{@member.id}", headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    assert body[:profile_attributes].key?(:cpf),
           'member must see own CPF on own profile — needed for the edit screen'
    assert body[:profile_attributes].key?(:zipcode),
           'member must see own address on own profile — needed for the edit screen'
  end

  # ----- phase v2 — /api/members listing must NOT expose phone to non-privileged

  test 'member listing does not expose phone to non-privileged callers' do
    get '/api/members?requested_attributes[]=profile', headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    assert body.is_a?(Array), 'index returns an array'
    body.each do |item|
      next unless item[:profile]

      refute item[:profile].key?(:phone),
             "member listing leaked profile.phone to a non-privileged caller (entry: #{item[:id]})"
    end
  end

  test 'admin listing still exposes phone (admins have legitimate access)' do
    logout(:user)
    login_as(@admin, scope: :user)
    get '/api/members?requested_attributes[]=profile', headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    has_phone = body.any? { |item| item[:profile]&.key?(:phone) }
    assert has_phone, 'admin must still see phone on listing — needed for administrative workflows'
  end

  # ----- phase v2 — /api/last_subscribed is public-minimum --------------------

  test 'last_subscribed public endpoint never returns email' do
    logout(:user) # explicitly anonymous
    get '/api/last_subscribed/4', headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    body.each do |item|
      refute item.key?(:email),
             'last_subscribed must not leak email to anonymous callers'
      refute item.key?(:username),
             'last_subscribed must not leak username to anonymous callers'
    end
  end

  test 'last_subscribed caps the result count regardless of the :last URL param' do
    logout(:user)
    # The route accepts a path param for backwards compatibility but the
    # service ignores it and caps at 10 to prevent the full-base enumeration
    # that the old signature allowed.
    get '/api/last_subscribed/9999', headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    assert body.size <= 10,
           "last_subscribed must cap at 10 server-side regardless of :last (was #{body.size})"
  end
end
