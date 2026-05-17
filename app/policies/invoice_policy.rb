# frozen_string_literal: true

# Check the access policies for API::InvoicesController
class InvoicePolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  # Reading a single invoice: owner (via invoicing_profile), or staff.
  # Mirrors `download?` — they were inconsistent before this fix.
  def show?
    user.admin? || user.manager? || (record.invoicing_profile.user_id == user.id)
  end

  def download?
    user.admin? || user.manager? || (record.invoicing_profile.user_id == user.id)
  end

  def create?
    user.admin? || user.manager?
  end

  def list?
    user.admin? || user.manager?
  end

  def first?
    user.admin?
  end
end
