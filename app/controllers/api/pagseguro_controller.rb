class API::PagseguroController < API::PaymentsController
    require 'pagseguro/helper'
    require 'pagseguro/service'
    
    # PagSeguro don't has a specific method for test API when send a list request for test token
    def test_token
        render json: {success: true}, status: :ok
    rescue StandardError => e
        render json: e, status: :unauthorized
    end

    # Create a request payment and return a object  with url for redirect to payment checkout
    def create_payment_link
        cart = shopping_cart
        amount = debit_amount(cart)

        @id = PagSeguro::Helper.generate_ref(params[:cart_items], params[:customer_id])

        payload = PagSeguro::Helper.generate_payload(
            amount,
            @id,
            PagSeguro::Helper.generate_sender(params[:customer_id]),
            PagSeguro::Helper.generate_items(params[:cart_items], current_user.id)
        )

        result = PagSeguro::Helper.make_pagseguro_request(payload)
        if result[:error].present?
            raise "Houve um erro na comunicação com o gateway, por favor tente mais tarde"
        end
        render json: result, status: :ok and return       
    rescue StandardError => e
        render json: e, status: :bad_gateway
    end
end
