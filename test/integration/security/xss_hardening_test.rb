# frozen_string_literal: true

require 'test_helper'

# Regression tests for the XSS Stored hardening — pentest 2026-05-17
# (item #22 in doc/security/pentest-2026-05-17.md).
#
# Before this fix, `PUT /api/members/:id` accepted `<script>` / `<svg onload>`
# payloads in `User#username`, `Profile#first_name`, and `Profile#last_name`.
# Even though the Angular frontend escapes `{{ }}` by default, the values
# bleed into mailer templates, generated PDFs, and any future JSX component
# using dangerouslySetInnerHTML.
#
# Fix:
#   - Profile: format validation (`NAME_FORMAT`) on `first_name` and
#     `last_name` (the fields the pentest actually exercised).
#   - User: format validation on `username`.
class XssHardeningTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.find(2) # jdupond
    login_as(@member, scope: :user)
  end

  test 'PUT /api/members/:self rejects <script> in username' do
    put "/api/members/#{@member.id}",
        params: { user: { current_password: 'letmein!?', username: '<script>1</script>',
                          profile_attributes: { first_name: 'Jean', last_name: 'Dupond', phone: '21999999999' } } }.to_json,
        headers: default_headers
    assert_equal 422, response.status
    body = json_response(response.body)
    assert body[:username].present?, 'username validation must reject the payload'
    @member.reload
    refute_includes @member.username.to_s, '<script>'
  end

  test 'PUT /api/members/:self rejects HTML in first_name' do
    put "/api/members/#{@member.id}",
        params: { user: { current_password: 'letmein!?',
                          profile_attributes: { first_name: '<img src=x onerror=alert(1)>', last_name: 'Dupond', phone: '21999999999' } } }.to_json,
        headers: default_headers
    assert_equal 422, response.status
    body = json_response(response.body)
    assert body[:"profile.first_name"].present?, 'first_name validation must reject HTML'
    @member.profile.reload
    refute_includes @member.profile.first_name.to_s, '<img'
  end

  test 'PUT /api/members/:self rejects HTML in last_name' do
    put "/api/members/#{@member.id}",
        params: { user: { current_password: 'letmein!?',
                          profile_attributes: { first_name: 'Jean', last_name: '"><script>1</script>', phone: '21999999999' } } }.to_json,
        headers: default_headers
    assert_equal 422, response.status
    body = json_response(response.body)
    assert body[:"profile.last_name"].present?, 'last_name validation must reject HTML'
  end

  test 'PUT /api/members/:self accepts legitimate Brazilian names with accents and punctuation' do
    put "/api/members/#{@member.id}",
        params: { user: { current_password: 'letmein!?',
                          profile_attributes: { first_name: 'João D\'Ávila', last_name: 'Silva-Santos',
                                                phone: '21999999999' } } }.to_json,
        headers: default_headers
    assert_equal 200, response.status, response.body
    @member.profile.reload
    assert_equal "João D'Ávila", @member.profile.first_name
    assert_equal 'Silva-Santos', @member.profile.last_name
  end
end
