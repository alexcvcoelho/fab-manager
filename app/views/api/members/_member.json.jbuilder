# frozen_string_literal: true

# When @restricted_member_show is true, the caller is a non-privileged user
# viewing somebody else's profile — we strip everything except the bare
# minimum needed to render a public-facing card (name, username, avatar,
# social profiles). PII (CPF, RG, mother_name, address, IP, etc.) MUST NOT
# be exposed in this branch. Adapted from upstream fa5489ae6 to cover the
# extra Firjan fields (CPF, RG, mother_name, address, financial_responsible_*).

json.extract! member, :username, :email, :slug
unless @restricted_member_show
  json.id member.id
  json.group_id member.group_id
  json.role member.roles.first.name
end
json.name member.profile.full_name
json.need_completion member.need_completion? unless @restricted_member_show
json.ip_address member.current_sign_in_ip.to_s unless @restricted_member_show
json.mapped_from_sso member.mapped_from_sso&.split(',') unless @restricted_member_show

json.profile_attributes do
  json.first_name member.profile.first_name
  json.last_name member.profile.last_name
  json.interest member.profile.interest
  json.software_mastered member.profile.software_mastered

  if @restricted_member_show
    # Public-facing social profiles only — these are explicitly opt-in fields
    # the member fills knowing they will be visible on their public card.
    json.facebook member.profile.facebook
    json.twitter member.profile.twitter
    json.viadeo member.profile.viadeo
    json.linkedin member.profile.linkedin
    json.instagram member.profile.instagram
    json.youtube member.profile.youtube
    json.vimeo member.profile.vimeo
    json.dailymotion member.profile.dailymotion
    json.github member.profile.github
    json.echosciences member.profile.echosciences
    json.pinterest member.profile.pinterest
    json.lastfm member.profile.lastfm
    json.flickr member.profile.flickr
  else
    json.id member.profile.id
    json.phone member.profile.phone
    json.website member.profile.website
    json.job member.profile.job
    if member.profile.user_avatar
      json.user_avatar_attributes do
        json.id member.profile.user_avatar.id
        json.attachment_url "#{member.profile.user_avatar.attachment_url}?#{member.profile.user_avatar.updated_at.to_i}"
      end
    end
    json.extract! member.profile, :facebook, :twitter, :viadeo, :linkedin, :instagram, :youtube, :vimeo, :dailymotion, :github, :echosciences, :pinterest, :lastfm, :flickr
    # Firjan-specific PII fields. These were the highest-severity leak vector
    # in the 2026-03 pentest — they MUST stay inside the privileged/self block.
    json.extract! member.profile, :cpf, :social_name, :origin_state, :origin_city, :zipcode, :street, :neighborhood, :number, :complement, :city, :state, :rg, :rg_date_emission, :rg_issuing_organization, :rg_issuing_state, :mother_name, :occupational_status, :education_level, :financial_responsible_name, :financial_responsible_cpf
    json.tours member.profile.tours&.split || []
  end
end

unless @restricted_member_show
  json.invoicing_profile_attributes do
    json.extract! member.invoicing_profile, :id, :external_id
    if member.invoicing_profile.address
      json.address_attributes do
        json.id member.invoicing_profile.address.id
        json.address member.invoicing_profile.address.address
      end
    end

    if member.invoicing_profile.organization
      json.organization_attributes do
        json.extract! member.invoicing_profile.organization, :id, :name
        if member.invoicing_profile.organization.address
          json.address_attributes do
            json.id member.invoicing_profile.organization.address.id
            json.address member.invoicing_profile.organization.address.address
          end
        end
      end
    end

    json.user_profile_custom_fields_attributes member.invoicing_profile.user_profile_custom_fields
      .joins(:profile_custom_field).where('profile_custom_fields.actived' => true).order('profile_custom_fields.id ASC') do |f|
      json.id f.id
      json.invoicing_profile_id f.invoicing_profile_id
      json.profile_custom_field_id f.profile_custom_field_id
      json.value f.value
    end
  end

  json.statistic_profile_attributes do
    json.id member.statistic_profile.id
    json.gender member.statistic_profile.gender.to_s
    json.birthday member.statistic_profile&.birthday&.to_date&.iso8601
    json.training_ids member.statistic_profile&.training_ids
  end

  if member.subscribed_plan
    json.subscribed_plan do
      json.partial! 'api/shared/plan', plan: member.subscribed_plan
    end
  end

  if member.subscription
    json.subscription do
      json.id member.subscription.id
      json.expired_at member.subscription.expired_at.iso8601
      json.canceled_at member.subscription.canceled_at.iso8601 if member.subscription.canceled_at
      json.plan do # TODO, refactor: duplicates subscribed_plan
        json.id member.subscription.plan.id
        json.base_name member.subscription.plan.base_name
        json.name member.subscription.plan.name
        json.interval member.subscription.plan.interval
        json.interval_count member.subscription.plan.interval_count
        json.amount member.subscription.plan.amount ? (member.subscription.plan.amount / 100.0) : 0
        json.monthly_payment member.subscription.plan.monthly_payment
      end
    end
  end
  json.training_credits member.training_credits do |tc|
    json.training_id tc.creditable_id
  end
  json.machine_credits member.machine_credits do |mc|
    json.machine_id mc.creditable_id
    json.hours_used mc.users_credits.find_by(user_id: member.id).hours_used
  end
  # TODO, missing space_credits?
  json.last_sign_in_at member.last_sign_in_at.iso8601 if member.last_sign_in_at
  json.validated_at member.validated_at
end
