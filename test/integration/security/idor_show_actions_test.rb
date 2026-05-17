# frozen_string_literal: true

require 'test_helper'

# Regression tests for the show-actions IDOR family closed in 2026-05-17.
#
# Background: a browser-driven pentest from inside the Firjan installation
# (see doc/security/pentest-2026-05-17.md) found that the `show` action of
# multiple controllers did not call `authorize`, even though the resource
# has a clear owner. Any logged-in member could read any other member's:
#
#   GET /api/invoices/:id              — leaks total/items/reference
#   GET /api/reservations/:id          — leaks user_full_name + usage
#   GET /api/orders/:id                — leaks cart token + invoice_id
#   GET /api/credits/:id               — administrative credit metadata
#   GET /api/supporting_document_files/:id — leaks filename + user_id
#
# Each fix added `authorize @record` to the controller's `show` and a
# matching `show?` predicate on the policy (or in Order's case, only the
# controller call — the policy was already correct).
#
# These tests pin the corrected behavior so a future rebase or refactor
# that drops the `authorize` call fails the build.
class IdorShowActionsTest < ActionDispatch::IntegrationTest
  setup do
    @member       = User.find(2) # jdupond — invoicing_profile_id 2, statistic_profile_id 2
    @other_member = User.find(4) # kdumas
    @admin        = User.find(1)
    login_as(@member, scope: :user)
  end

  # ----- /api/invoices/:id -----------------------------------------------------

  test 'member cannot read another members invoice' do
    # invoice_1 belongs to invoicing_profile_id 3 (not jdupond's 2)
    get '/api/invoices/1', headers: default_headers
    assert_equal 403, response.status,
                 'member must not be able to read other members\' invoices'
  end

  test 'admin can read any invoice' do
    logout(:user)
    login_as(@admin, scope: :user)
    get '/api/invoices/1', headers: default_headers
    assert_equal 200, response.status, response.body
  end

  # ----- /api/reservations/:id -------------------------------------------------

  test 'member cannot read another members reservation' do
    # reservation_1 belongs to statistic_profile_id 7
    get '/api/reservations/1', headers: default_headers
    assert_equal 403, response.status,
                 'member must not be able to read other members\' reservations (leaks user_full_name)'
  end

  test 'admin can read any reservation' do
    logout(:user)
    login_as(@admin, scope: :user)
    get '/api/reservations/1', headers: default_headers
    assert_equal 200, response.status, response.body
  end

  # ----- /api/orders/:id -------------------------------------------------------

  test 'member cannot read another members order' do
    # order_1 belongs to statistic_profile_id 3 (not jdupond's 2)
    get '/api/orders/1', headers: default_headers
    assert_equal 403, response.status,
                 'member must not be able to read other members\' orders (leaks cart token)'
  end

  # ----- /api/credits/:id ------------------------------------------------------

  test 'member cannot read individual credit (admin-only)' do
    get '/api/credits/1', headers: default_headers
    assert_equal 403, response.status,
                 'credits are administrative metadata — only admins can read individual credit records'
  end

  test 'admin can read any credit' do
    logout(:user)
    login_as(@admin, scope: :user)
    get '/api/credits/1', headers: default_headers
    assert_equal 200, response.status, response.body
  end

  # ----- /api/supporting_document_files/:id ------------------------------------

  test 'member cannot read another members supporting document file' do
    file = SupportingDocumentFile.create!(
      supporting_document_type_id: 1,
      user_id: @other_member.id,
      attachment: fixture_file_upload(Rails.root.join('test/fixtures/files/document.pdf'), 'application/pdf')
    )
    get "/api/supporting_document_files/#{file.id}", headers: default_headers
    assert_equal 403, response.status,
                 'member must not be able to read other members\' supporting document files (leaks filename + user_id)'
  end

  test 'member can read own supporting document file' do
    file = SupportingDocumentFile.create!(
      supporting_document_type_id: 1,
      user_id: @member.id,
      attachment: fixture_file_upload(Rails.root.join('test/fixtures/files/document.pdf'), 'application/pdf')
    )
    get "/api/supporting_document_files/#{file.id}", headers: default_headers
    assert_equal 200, response.status, response.body
  end
end
