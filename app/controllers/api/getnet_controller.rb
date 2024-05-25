# frozen_string_literal: true

# API Controller for accessing Getnet API endpoints through the front-end app
class API::GetnetController < API::PaymentsController
  require 'getnet/authentication'

  def sdk_test
    str = 'fab-manager'

    client = Getnet::Authentication.new(base_url: params[:endpoint], client_id: params[:client_id], client_secret: params[:client_secret])
    res = client.get_token

    puts res

    @status = (res['answer'] != "")
  rescue SocketError
    @status = false
  end
end
