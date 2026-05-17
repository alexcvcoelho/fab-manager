# frozen_string_literal: true

# Check the access policies for API::CreditsController
class CreditPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  # Credits are tied to subscription plans (not to a single owner user),
  # so reading an individual credit is administrative. The per-user view
  # of available credits is exposed by `user_resource?` below, which still
  # enforces ownership.
  def show?
    user.admin?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  def user_resource?
    record.id == user.id
  end
end
