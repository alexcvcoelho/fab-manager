# frozen_string_literal: true

# Check the access policies for API::MembersController and API::UsersController
class UserPolicy < ApplicationPolicy
  # Defines the scope of the users index, depending on the role of the current user
  class Scope < Scope
    def resolve
      if user.admin?
        scope.includes(:group, :training_credits, :machine_credits, statistic_profile: [subscriptions: [plan: [:credits]]], profile: [:user_avatar])
             .joins(:roles).where("users.is_active = 'true' AND roles.name = 'member'").order('users.created_at desc')
      else
        scope.includes(profile: [:user_avatar]).joins(:roles).where("users.is_active = 'true' AND roles.name = 'member'")
             .where(is_allow_contact: true).order('users.created_at desc')
      end
    end
  end

  # Authorize reading a user's full profile.
  #
  # The previous predicate granted access whenever `record.is_allow_contact &&
  # record.member?` was true, which exposed PII (CPF, RG, mother's name,
  # address, IP) of every member with the "allow contact" flag — i.e. almost
  # the entire member base — to any authenticated user. Reported by external
  # pentest in 2026-03 and confirmed exploitable in 2026-05. See
  # doc/security/README.md.
  #
  # `is_allow_contact` is preserved as a flag for the members directory
  # (Members::ListService and Members::MembersService), where it filters
  # who appears as available for contact. It must NOT regrant access to
  # the full profile here.
  def show?
    user.admin? || user.manager? || (user.id == record.id)
  end

  def current?
    user.admin? || user.manager? || (user.id == record.id)
  end

  def update?
    user.admin? || user.manager? || (user.id == record.id)
  end

  def destroy?
    user.admin? || (user.id == record.id)
  end

  %w[merge complete_tour].each do |action|
    define_method "#{action}?" do
      user.id == record.id
    end
  end

  %w[list index create_member validate].each do |action|
    define_method "#{action}?" do
      user.admin? || user.manager?
    end
  end

  %w[create mapping update_role].each do |action|
    define_method "#{action}?" do
      user.admin?
    end
  end
end
