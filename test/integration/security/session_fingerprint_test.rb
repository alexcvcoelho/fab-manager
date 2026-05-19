# frozen_string_literal: true

require 'test_helper'

# Regression test for the session fingerprint binding — Claupper's Q2c
# in doc/security/resposta-claupper-2026-05-17.md.
#
# Before this fix, a `_Fab-manager_session` cookie exfiltrated from one
# device worked anywhere — Rhamadan reproduced this in the 2026-05-14
# print (Session Hijacking).
#
# The fix in ApplicationController#validate_session_fingerprint pins the
# session to a fingerprint of the caller's IP /24 + User-Agent. If
# either changes mid-session, the request is rejected with 401 and the
# session is dropped.
class SessionFingerprintTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.find(2) # jdupond
    login_as(@member, scope: :user)
  end

  test 'same IP subnet + same UA continues working' do
    headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.10',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    # First request seeds the fingerprint
    get "/api/members/#{@member.id}", headers: headers
    assert_equal 200, response.status, 'first authenticated request records the fingerprint'

    # Same fingerprint = still allowed
    get "/api/members/#{@member.id}", headers: headers
    assert_equal 200, response.status, 'matching fingerprint must pass'
  end

  test 'request from a different IP /24 subnet is rejected with 401' do
    seed_headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.10',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    get "/api/members/#{@member.id}", headers: seed_headers
    assert_equal 200, response.status, response.body

    # Replay the same session cookie from a different /24
    hijack_headers = default_headers.merge(
      'REMOTE_ADDR' => '10.0.0.10',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    get "/api/members/#{@member.id}", headers: hijack_headers
    assert_equal 401, response.status,
                 'replay from a different subnet must invalidate the session'
  end

  test 'request from same subnet but different User-Agent is rejected' do
    seed_headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.10',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    get "/api/members/#{@member.id}", headers: seed_headers
    assert_equal 200, response.status, response.body

    forged_ua_headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.99',  # same /24
      'HTTP_USER_AGENT' => 'curl/8.0.0' # different UA
    )
    get "/api/members/#{@member.id}", headers: forged_ua_headers
    assert_equal 401, response.status,
                 'UA change in the same subnet must still invalidate (attacker on same WiFi)'
  end

  test 'same /24 with last-octet change is allowed (mobile NAT scenario)' do
    seed_headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.10',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    get "/api/members/#{@member.id}", headers: seed_headers
    assert_equal 200, response.status

    same_subnet_headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.250', # different host, same /24
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    get "/api/members/#{@member.id}", headers: same_subnet_headers
    assert_equal 200, response.status,
                 'movement within the same /24 (carrier-grade NAT) should not invalidate the session'
  end

  # Production rollback path — see ApplicationController comment.
  # When SKIP_SESSION_FINGERPRINT=true is set, only the UA component is
  # used. Cross-subnet replay with the SAME UA is allowed (so admins
  # behind Azure App Service's rotating load balancer keep their
  # session); replay with a DIFFERENT UA is still rejected.
  test 'SKIP_SESSION_FINGERPRINT=true allows cross-subnet replay with same UA' do
    ENV['SKIP_SESSION_FINGERPRINT'] = 'true'

    seed_headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.10',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    get "/api/members/#{@member.id}", headers: seed_headers
    assert_equal 200, response.status

    # Same cookie, different /24 but same UA — must pass under UA-only mode
    cross_subnet_headers = default_headers.merge(
      'REMOTE_ADDR' => '10.0.0.10',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    get "/api/members/#{@member.id}", headers: cross_subnet_headers
    assert_equal 200, response.status,
                 'with SKIP_SESSION_FINGERPRINT=true cross-subnet + same UA must pass'
  ensure
    ENV.delete('SKIP_SESSION_FINGERPRINT')
  end

  test 'SKIP_SESSION_FINGERPRINT=true still rejects UA mismatch' do
    ENV['SKIP_SESSION_FINGERPRINT'] = 'true'

    seed_headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.10',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) Test/1.0'
    )
    get "/api/members/#{@member.id}", headers: seed_headers
    assert_equal 200, response.status

    # Cookie replayed with curl from anywhere — different UA must still 401
    forged_ua_headers = default_headers.merge(
      'REMOTE_ADDR' => '192.168.1.10',
      'HTTP_USER_AGENT' => 'curl/8.0.0'
    )
    get "/api/members/#{@member.id}", headers: forged_ua_headers
    assert_equal 401, response.status,
                 'UA mismatch must invalidate even under UA-only mode'
  ensure
    ENV.delete('SKIP_SESSION_FINGERPRINT')
  end
end
