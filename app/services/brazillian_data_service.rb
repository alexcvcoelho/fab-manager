# frozen_string_literal: true

# This class provides helper methods to search brazillian data
class BrazillianDataService
  require 'net/http'
  require 'uri'

  def list_states
    endpoint = "https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome"
    uri = URI(endpoint)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = "application/json"
      response = http.request request

      if response.code.to_i == 200
        puts "RESPONSE #{response.body}"
        result = JSON.parse(response.body) 
        result
      else
        []
      end
    end
  end

  def list_cities(uf)
    endpoint = "https://servicodados.ibge.gov.br/api/v1/localidades/estados/#{uf}/municipios?orderBy=nome"
    uri = URI(endpoint)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = "application/json"
      response = http.request request

      if response.code.to_i == 200
        puts "RESPONSE #{response.body}"
        result = JSON.parse(response.body) 
        result
      else
        []
      end
    end
  end

  def search_zipcode(zipcode)
    endpoint = "https://viacep.com.br/ws/#{zipcode}/json/"
    uri = URI(endpoint)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = "application/json"
      response = http.request request

      if response.code.to_i == 200
        puts "RESPONSE #{response.body}"
        result = JSON.parse(response.body) 
        result
      else
        {}
      end
    end
  end
end
