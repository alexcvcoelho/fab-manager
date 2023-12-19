class API::BrazillianDataController < ApplicationController
    before_action :authenticate_user!, except: [:all_states, :cities, :zipcode]

    def all_states
        service = BrazillianDataService.new()
        states = service.list_states
        render json: states, status: :ok 
    end

    def cities
        @uf = params[:uf]
        service = BrazillianDataService.new()
        cities = service.list_cities(@uf)
        render json: cities, status: :ok 
    end

    def zipcode
        @zip = params[:zip].gsub(/\D/, '')
        service = BrazillianDataService.new()
        zip_data = service.search_zipcode(@zip)
        render json: zip_data, status: :ok 
    end
end
