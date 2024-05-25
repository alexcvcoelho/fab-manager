require 'getnet/client'

# Authentication/* endpoints of the Getnet REST API
class Getnet::Authentication < Getnet::Client
  def initialize(base_url: nil, client_id: nil, client_secret: nil)
    super(base_url: base_url, client_id: client_id, client_secret: client_secret)
  end

  def get_token
    auth
  end
end