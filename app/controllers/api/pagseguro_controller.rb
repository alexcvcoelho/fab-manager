class API::PagseguroController < API::PaymentsController
    require 'pagseguro/helper'
    require 'pagseguro/service'
    require 'json'

    skip_before_action :authenticate_user!, only: :notify
    skip_before_action :verify_authenticity_token, only: :notify
    
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

        puts "PASSOU"
        @pagseguro_intent = PagseguroIntent.new(reference_code: @id, payment_code: result[:code], shopping_cart: cart.to_json, status: "pending")
        @pagseguro_intent.save

        #render on_payment_success(@id, cart)
        render json: result, status: :ok and return       
    rescue StandardError => e
        render json: e, status: :bad_gateway
    end

    def notify
        render(json: { error: 'Bad gateway or online payment is disabled' }, status: :bad_gateway) and return unless PagSeguro::Helper.enabled?
        render(status: :ok) and return unless params['notificationType'] == 'transaction'

        result = PagSeguro::Helper.get_transaction_by_code(params['notificationCode'])
        render(status: :ok) and return unless result[:status] == "3"

        pagseguro_intent = PagseguroIntent.find_by(reference_code: result[:code])

        cart_hash = JSON.parse(pagseguro_intent[:shopping_cart], symbolize_names: true)
        puts cart_hash

        @user = User.find(cart_hash[:operator][:id])
        cs = CartService.new(@user)
        cart = cs.from_hash(cart_hash)

        pagseguro_intent.status = 'paid'
        pagseguro_intent.save

        render on_payment_success(result[:code], cart)
    end
    
    def on_payment_success(order_id, cart)
        super(order_id, 'PagSeguro::Transaction', cart)
    end
end
