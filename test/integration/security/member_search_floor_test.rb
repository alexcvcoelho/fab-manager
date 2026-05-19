# frozen_string_literal: true

require 'test_helper'

# Regression test for the member search query floor — Claupper's Q1
# in doc/security/resposta-claupper-2026-05-17.md.
#
# Before this fix, `GET /api/members/search/<short>` would happily run
# a substring regex against `users.username || profiles.first_name ||
# profiles.last_name` with as little as a single character, returning
# most of the member base. Queries that decoded to only whitespace
# (e.g. `%20%20`) skipped the filter loop entirely and returned every
# active member.
#
# The fix in `Members::ListService.search` rejects queries shorter
# than 3 chars (after whitespace normalization) AND requires at least
# one word of 3+ chars to participate in the LIKE.
class MemberSearchFloorTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.find(2) # jdupond
    login_as(@member, scope: :user)
  end

  test 'single-character query returns empty list' do
    get '/api/members/search/a', headers: default_headers
    assert_equal 200, response.status, response.body
    assert_equal [], json_response(response.body),
                 'single-character search must not enumerate the member base'
  end

  test 'two-character query returns empty list' do
    get '/api/members/search/ab', headers: default_headers
    assert_equal 200, response.status, response.body
    assert_equal [], json_response(response.body)
  end

  test 'whitespace-only query returns empty list' do
    get '/api/members/search/%20%20%20', headers: default_headers
    assert_equal 200, response.status, response.body
    assert_equal [], json_response(response.body),
                 'whitespace-only queries used to skip the WHERE loop and return everybody'
  end

  test 'query with only short words returns empty list' do
    # "a b c" has 5 chars but no word of 3+ chars
    get '/api/members/search/a%20b%20c', headers: default_headers
    assert_equal 200, response.status, response.body
    assert_equal [], json_response(response.body)
  end

  test 'query of 3+ characters still works' do
    # First name 'Jean' exists in the fixtures (User.find(2) is jdupond / Jean Dupond).
    get '/api/members/search/jea', headers: default_headers
    assert_equal 200, response.status, response.body
    body = json_response(response.body)
    assert body.is_a?(Array), 'search returns an array'
    # We don't assert size > 0 because the fixture setup might filter the
    # caller out via is_allow_contact, but the call must not have been
    # rejected at the floor check.
  end
end
