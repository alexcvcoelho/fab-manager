# frozen_string_literal: true

# API Controller for resources of type User with role 'admin'.
class API::AdminsController < API::APIController
  before_action :authenticate_user!

  def index
    authorize :admin
    @admins = User.includes(profile: [:user_avatar]).admins
  end

  def create
    authorize :admin
    res = UserService.create_admin(admin_params)

    if res[:saved]
      @admin = res[:user]
      render :create, status: :created
    else
      render json: res[:user].errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    @admin = User.admins.find(params[:id])
    if current_user.admin? && @admin != current_user
      @admin.destroy
      head :no_content
    else
      head :unauthorized
    end
  end

  private

  def admin_params
    params.require(:admin).permit(
      :username, :email, :group_id,
      profile_attributes: %i[first_name last_name phone cpf social_name origin_state origin_city zipcode street neighborhood number complement city state rg rg_date_emission rg_issuing_organization rg_issuing_state mother_name occupational_status education_level financial_responsible_name financial_responsible_cpf],
      invoicing_profile_attributes: [address_attributes: [:address]],
      statistic_profile_attributes: %i[gender birthday]
    )
  end
end
