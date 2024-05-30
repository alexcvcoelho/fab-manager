require 'getnet/client'

# Authentication/* endpoints of the Getnet REST API
class Getnet::Card < Getnet::Client
  def initialize(base_url: nil, client_id: nil, client_secret: nil, seller_id: nil)
    super(base_url: nil, client_id: nil, client_secret: nil, seller_id: nil)
  end

  def create_token(payload)
    post('/v1/tokens/card', payload)
  end
end