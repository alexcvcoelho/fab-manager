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

    @status = (res != '')
  rescue SocketError
    @status = false
  end

  def token_card
    payload = GetNet::Helper.card_token(params[:card_number], params[:customer_id])
    client = Getnet::Card.new
    res = client.create_token(payload)

    @token = res['number_token']
  rescue SocketError
    @status = false
  end

  def create_payment
    cart = shopping_cart
    amount = debit_amount(cart)
    @id = GetNet::Helper.generate_ref(params[:cart_items], params[:customer_id])
    @card = params[:card]

    client = Getnet::Card.new
    @result = client.create_payment(seller_id: Setting.get('getnet_seller_id'),
                                    amount: amount[:amount],
                                    order: GetNet::Helper.generate_order(@id),
                                    customer: GetNet::Helper.generate_customer(params[:customer_id]),
                                    device: GetNet::Helper.generate_device(request),
                                    credit: GetNet::Helper.generate_credit(@card))

    if @result.present?
      GetnetTransaction.create!(
        order_id: @id,
        payload: @result
      )
    end

    @result
  rescue GetnetError => e
    render json: e, status: :unprocessable_entity
  end

  def confirm_payment
    cart = shopping_cart

    ActiveRecord::Base.transaction do
      result = on_payment_success(params[:order_id], cart)
      invoice = result[:locals][:invoice]
      puts invoice
      transaction = GetnetTransaction.find_by(order_id: params[:order_id])
      if transaction.present?
        transaction.invoice_id = invoice.id
        transaction.save!
      end
      render result
    end
  rescue StandardError => e
    render json: e, status: :unprocessable_entity
  end

  private

  def on_payment_success(order_id, cart)
    super(order_id, 'GetNet::Order', cart)
  end
end
