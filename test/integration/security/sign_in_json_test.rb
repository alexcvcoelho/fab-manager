# frozen_string_literal: true

require 'test_helper'

# Regression test for pentest 2026-05-17 item E (relatorio-2026-05-17.md):
# `GET /users/sign_in.json` previously returned 500 (Rails couldn't find a
# JSON template for Devise's sign-in form). Now returns a clean 405.
class SignInJsonTest < ActionDispatch::IntegrationTest
  test 'GET /users/sign_in.json returns 405 (not 500)' do
    get '/users/sign_in.json'
    assert_equal 405, response.status,
                 'GET on the sign-in form with a JSON Accept header must be a clean Method Not Allowed, not a 500'
  end

  test 'GET /users/sign_in (HTML) still works for the form rendering' do
    get '/users/sign_in'
    # Devise's GET sign_in renders a form (200) or redirects to the SSO
    # provider; either is fine. What MUST NOT happen is a 500.
    refute_equal 500, response.status,
                 'the HTML sign-in path must remain unaffected by the JSON guard'
  end
end
