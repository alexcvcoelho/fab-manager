# frozen_string_literal: true

require 'test_helper'

# Regression tests for the data minimization layer of API::GroupsController#index.
#
# Background: Firjan's security team reported in 2026-05 that
# `GET /api/groups` exposed the per-group member count to any caller —
# including unauthenticated visitors and regular members. While the listing
# itself must stay public (the signup modal calls it to populate the group
# picker), the `users.count` field is administrative metadata that has no
# business being exposed to non-privileged callers.
#
# Fix: gated `json.users group.users.count` in `_group.json.jbuilder` behind
# `unless @restricted_groups_index`, where the flag is set to
# `!current_user&.privileged?` in the controller.
class GroupsIndexTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.find(2) # jdupond, role: member
    @admin  = User.find(1)
  end

  test 'anonymous caller (signup modal) sees groups but no users count' do
    get '/api/groups', headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    assert body.is_a?(Array) && body.any?, 'index must return groups'
    body.each do |g|
      assert g.key?(:id), 'signup modal needs :id'
      assert g.key?(:name), 'signup modal needs :name'
      refute g.key?(:users),
             "members count must not be exposed to anonymous callers (group #{g[:id]})"
    end
  end

  test 'regular member sees groups but no users count' do
    login_as(@member, scope: :user)
    get '/api/groups', headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    body.each do |g|
      refute g.key?(:users),
             "members count must not be exposed to regular members (group #{g[:id]})"
    end
  end

  test 'admin sees users count (administrative metadata)' do
    login_as(@admin, scope: :user)
    get '/api/groups', headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    assert body.any? { |g| g.key?(:users) },
           'admin must keep seeing :users (members count) — used by admin UIs'
  end
end
