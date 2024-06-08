# frozen_string_literal: true

# API Controller for accessing Getnet API endpoints through the front-end app
class API::GetnetController < API::PaymentsController
  require 'getnet/authentication'
  require 'getnet/card'
  require 'getnet/helper'

  def sdk_test
    str = 'fab-manager'

    client = Getnet::Authentication.new(base_url: params[:endpoint], client_id: params[:client_id], client_secret: params[:client_secret])
    res = client.get_token

    @status = (res != "")
  rescue SocketError
    @status = false
  end

  def token_card
    payload = Getnet::Helper.card_token(params[:card_number], params[:customer_id])
    client = Getnet::Card.new()
    res = client.create_token(payload)

    @token = res['number_token']
  rescue SocketError
    @status = false
  end

  def create_payment
    cart = shopping_cart
    amount = debit_amount(cart)
    @id = Getnet::Helper.generate_ref(params[:cart_items], params[:customer_id])

    client = Getnet::Card.new
    @result = client.create_payment(seller_id: Setting.get('getnet_seller_id'),
                                    amount: amount,
                                    order: Getnet::Helper.generate_order(@id),
                                    customer: Getnet::Helper.generate_customer(params[:customer_id], current_user.id, order),
                                    device: Getnet::Helper.generate_device(request),
                                    credit: Getnet::Helper.generate_credit(order.statistic_profile.user.id, order))
    
    client.create_payment(amount: PayZen::Service.new.payzen_amount(amount[:amount]),
                                    order_id: @id,
                                    customer: PayZen::Helper.generate_customer(params[:customer_id], current_user.id, params[:cart_items]))
  rescue GetnetError => e
    render json: e, status: :unprocessable_entity
  end
end
