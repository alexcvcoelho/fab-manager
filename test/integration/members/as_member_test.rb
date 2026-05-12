# frozen_string_literal: true

require 'test_helper'

# Regression tests for the authorization layer of API::MembersController#show.
#
# Background: a pentest reported in 2026-03 that any authenticated user could
# read another member's full profile (CPF, RG, mother's name, address, IP) by
# changing the :id in `GET /api/members/:id`. The root cause was a permissive
# clause in `UserPolicy#show?` that granted access whenever the target had
# `is_allow_contact: true` (the default on signup), regardless of the
# requesting user. See doc/security/README.md.
#
# These tests pin the corrected behavior so a future rebase against upstream
# (which may carry the original predicate back) fails the build instead of
# silently reopening the vulnerability.
class MembersAsMemberTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.find(2)        # jdupond, role: member, is_allow_contact: true
    @other_member = User.find(4)  # kdumas, role: member, is_allow_contact: true
    @admin = User.find(1)
    login_as(@member, scope: :user)
  end

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
end
