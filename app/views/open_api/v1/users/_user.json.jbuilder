# frozen_string_literal: true

json.extract! user, :id, :email, :created_at
json.extract! user.profile, :full_name, :first_name, :last_name, :cpf, :social_name, :origin_state, :origin_city, :zipcode, :street, :neighborhood, :number, :complement, :city, :state, :rg, :rg_date_emission, :rg_issuing_organization, :rg_issuing_state, :mother_name, :occupational_status, :education_level, :financial_responsible_name, :financial_responsible_cpf if user.association(:profile).loaded?
json.gender user.statistic_profile.gender ? 'man' : 'woman'

if user.association(:invoicing_profile).loaded?
  json.invoicing_profile_id user.invoicing_profile.id
  json.external_id user.invoicing_profile.external_id
  json.organization !user.invoicing_profile.organization.nil?
end

if user.association(:group).loaded?
  json.group do
    if user.group_id?
      json.extract! user.group, :id, :name, :slug
    else
      json.nil!
    end
  end
end
