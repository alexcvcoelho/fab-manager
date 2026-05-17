# frozen_string_literal: true

user_is_admin = current_user&.admin?
max_members = @query.except(:offset, :limit, :order).count

json.array!(@members) do |member|
  json.id member.id
  json.maxMembers max_members unless @public_last_subscribed

  if @public_last_subscribed
    # `/api/members/last_subscribed` is unauthenticated. Strip everything
    # except the absolute minimum needed for the homepage widget.
    json.name member.profile.full_name
    if member.profile.user_avatar
      json.avatar do
        json.id member.profile.user_avatar.id
        json.attachment_url member.profile.user_avatar.attachment_url
      end
    end
  elsif !@restricted_member_index
    # Privileged listing (admin/manager): full administrative payload.
    json.username member.username
    json.slug member.slug
    json.name member.profile.full_name
    json.email member.email if current_user
    json.first_name member.profile.first_name
    json.last_name member.profile.last_name
    json.need_completion member.need_completion?
    json.group_id member.group_id
  end
  # Firjan-specific stricter-than-upstream behavior: when @restricted_member_index
  # is set (any non-privileged caller), the listing returns only `id` and
  # `maxMembers` — no email, username, slug, name, group_id, etc.
  #
  # Rationale: the Firjan installation hides the public members directory
  # via feature flag, so non-privileged members have no legitimate UI flow
  # that consumes this endpoint. Upstream `fa5489ae6` left email/name/slug
  # exposed to any logged-in user; we go further to prevent enumeration of
  # the member base (the exact vector the 2026-05 Firjan security team
  # report flagged after the first round of fixes was deployed).

  if !@public_last_subscribed && !@restricted_member_index && attribute_requested?(@requested_attributes, 'profile')
    json.profile do
      if member.profile.user_avatar
        json.user_avatar do
          json.id member.profile.user_avatar.id
          json.attachment_url member.profile.user_avatar.attachment_url
        end
      end
      json.first_name member.profile.first_name
      json.last_name member.profile.last_name
      json.phone member.profile.phone
    end
    if user_is_admin
      json.statistic_profile do
        json.gender member.statistic_profile.gender.to_s
        json.birthday member.statistic_profile&.birthday&.iso8601
      end
    end
  end

  if !@restricted_member_index && attribute_requested?(@requested_attributes, 'group') && member.group
    json.group do
      json.id member.group.id
      json.name member.group.name
    end
  end

  if !@restricted_member_index && attribute_requested?(@requested_attributes, 'subscription')
    if user_is_admin
      if member.subscribed_plan
        json.subscribed_plan do
          json.partial! 'api/shared/plan', plan: member.subscribed_plan
        end
      end
      if member.subscription
        json.subscription do
          json.id member.subscription.id
          json.expired_at member.subscription.expired_at.iso8601
          json.canceled_at member.subscription&.canceled_at&.iso8601
          json.plan do
            json.id member.subscription.plan.id
            json.name member.subscription.plan.name
            json.base_name member.subscription.plan.base_name
            json.interval member.subscription.plan.interval
            json.amount member.subscription.plan.amount ? (member.subscription.plan.amount / 100.0) : 0
          end
        end
      end
    end
  end

  if !@restricted_member_index && (attribute_requested?(@requested_attributes, 'credits') || attribute_requested?(@requested_attributes, 'training_credits'))
    json.training_credits member.training_credits do |tc|
      json.training_id tc.creditable_id
    end
  end

  if !@restricted_member_index && (attribute_requested?(@requested_attributes, 'credits') || attribute_requested?(@requested_attributes, 'machine_credits'))
    json.machine_credits member.machine_credits do |mc|
      json.machine_id mc.creditable_id
      json.hours_used mc.users_credits.find_by(user_id: member.id).hours_used
    end
  end

  if !@restricted_member_index && attribute_requested?(@requested_attributes, 'tags')
    json.tags member.tags do |t|
      json.id t.id
      json.name t.name
    end
  end
end
