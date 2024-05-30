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

    @token = res
  rescue SocketError
    @status = false
  end
end
