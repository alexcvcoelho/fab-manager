module Getnet; end

API_AUTH_PATH = '/auth/oauth/v2/token'

class Getnet::Client
  def initialize(base_url: nil, client_id: nil, client_secret: nil, seller_id: mil)
    @base_url = base_url
    @client_id = client_id
    @client_secret = client_secret
    @seller_id  = seller_id
  end

  protected

  def auth
    require 'uri'
    require 'net/http'
    require 'json'

    uri = URI(File.join(base_url, API_AUTH_PATH))
    headers = {
      'Authorization' => authorization_header,
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    res = Net::HTTP.post_form(uri, grant_type: 'client_credentials', scope: 'oob')
    raise ::GetnetError unless res.is_a?(Net::HTTPSuccess)

    json = JSON.parse(res.body)
    raise ::GetnetError, json['answer'] if json['status'] == 'ERROR'

    token(json)
  end

  def base_url
    @base_url || Setting.get('getnet_endpoint')
  end

  def authorization_header
    client_id = @client_id || Setting.get('getnet_client_id')
    client_secret = @client_secret || Setting.get('getnet_client_secret')

    credentials = Base64.strict_encode64("#{client_id}:#{client_secret}")
    "Basic #{credentials}"
  end

  def token(auth_response)
    "#{auth_response['token_type']} #{auth_response['access_token']}"
  end
end