# frozen_string_literal: true

require 'test_helper'

# Regression tests for the XSS Stored hardening — pentest 2026-05-17
# (item #22 in doc/security/pentest-2026-05-17.md).
#
# Before this fix, `PUT /api/members/:id` accepted `<script>`/`<svg onload>`
# payloads in:
#   - User#username
#   - Profile#first_name, last_name, social_name, mother_name
#   - Profile#interest, software_mastered, note (free-form)
#
# Even though the Angular frontend escapes `{{ }}` by default, the
# values bleed into:
#   - mailer templates (10+ files in app/views/notifications_mailer)
#   - generated PDFs (invoices, statements)
#   - any future React/JSX component using dangerouslySetInnerHTML
#
# Fix:
#   - Profile: format validation (`NAME_FORMAT` whitelist) for name-like
#     fields; `strip_tags` (via ActionController helpers) for free-form
#     fields in `before_validation`.
#   - User: format validation for `username`.
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

  test 'PUT /api/members/:self strips HTML from interest (free-form)' do
    put "/api/members/#{@member.id}",
        params: { user: { current_password: 'letmein!?',
                          profile_attributes: { first_name: 'Jean', last_name: 'Dupond', phone: '21999999999',
                                                interest: '<img src=x onerror=alert(1)>I enjoy 3D printing' } } }.to_json,
        headers: default_headers
    assert_equal 200, response.status, response.body
    @member.profile.reload
    refute_includes @member.profile.interest.to_s, '<img'
    refute_includes @member.profile.interest.to_s, 'onerror'
    assert_includes @member.profile.interest.to_s, '3D printing',
                    'strip_tags must keep the plain text content'
  end

  test 'PUT /api/members/:self accepts legitimate Brazilian names with accents and punctuation' do
    put "/api/members/#{@member.id}",
        params: { user: { current_password: 'letmein!?',
                          profile_attributes: { first_name: 'João D\'Ávila', last_name: 'Silva-Santos',
                                                social_name: 'João (Joca)', mother_name: 'Maria José D\'Ávila',
                                                phone: '21999999999' } } }.to_json,
        headers: default_headers
    assert_equal 200, response.status, response.body
    @member.profile.reload
    assert_equal "João D'Ávila", @member.profile.first_name
    assert_equal 'Silva-Santos', @member.profile.last_name
    assert_equal 'João (Joca)', @member.profile.social_name
    assert_equal "Maria José D'Ávila", @member.profile.mother_name
  end
end
