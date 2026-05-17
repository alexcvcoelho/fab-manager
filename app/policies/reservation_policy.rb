# frozen_string_literal: true

# Check the access policies for API::ReservationsController
class ReservationPolicy < ApplicationPolicy
  def create?
    user.admin? || (user.manager? && record.user_id != user.id) || record.price.zero?
  end

  # Reading a single reservation: owner, or staff. The previous absence of
  # this predicate combined with `ReservationsController#show` not calling
  # `authorize` was an IDOR (any logged-in user could read someone else's
  # reservation, including `user_full_name`). See doc/security/pentest-2026-05-17.md.
  def show?
    user.admin? || user.manager? || record.user == user
  end

  def update?
    user.admin? || user.manager? || record.user == user
  end
end
