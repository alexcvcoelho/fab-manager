class API::BrazillianDataController < ApplicationController
    before_action :authenticate_user!, except: [:all_states, :cities]

    def all_states
        render json: [{id: 'SP', name: 'São Paulo'}, {id: 'MS', name: 'Mato Grosso do Sul'}], status: :ok 
    end

    def cities
        @uf = params[:uf]
        render json: [{sigla: @uf, name: 'São Paulo'}], status: :ok 
    end
end
