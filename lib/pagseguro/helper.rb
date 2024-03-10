# frozen_string_literal: true

# PagSeguro payement gateway
module PagSeguro; end

## Provides various methods around the PagSeguro payment gateway
class PagSeguro::Helper
  class << self
    require 'net/http'
    require 'uri'

    ## Is the PagSeguro gateway enabled?
    def enabled?
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'pagseguro'

      res = true
      %w[pagseguro_token pagseguro_email].each do |pg_setting|
        res = false unless Setting.get(pg_setting).present?
      end
      res
    end

    def human_error(error)
      I18n.t('errors.messages.gateway_error', { MESSAGE: error.message })
    end

    ## generate an unique string reference for the content of a cart
    def generate_ref(cart_items, customer)
      require 'sha3'

      content = { cart_items: cart_items, customer: customer }.to_json + DateTime.current.to_s
      # It's safe to truncate a hash. See https://crypto.stackexchange.com/questions/74646/sha3-255-one-bit-less
      SHA3::Digest.hexdigest(:sha224, content)[0...24]
    end

    ## Create sender informations
    def generate_sender_v2(customer_id)
      customer = User.find(customer_id)
      {
        name: customer.profile.full_name,
        email: customer.email,
        cpf: customer.profile.cpf
      }
    end

    ## generate hasgmap compatipble with pagseguro request
    def generate_items_v2(cart_items, operator_id)
      operator = User.find(operator_id)
      items = []
      cart =  case cart_items
              when ShoppingCart, Order
                cart_items
              else
                cs = CartService.new(operator)
                cs.from_hash(cart_items)
              end

      if cart.is_a? Order
        cart.order_items.map do |item|
          items << {
            id: item.orderable_id,
            description: 'RESERVA FABLAB',
            amount: item.amount.to_i,
            quantity: item.quantity.to_i
          }
        end
        return items
      end

      cart.items.map do |item|
        items << {
          id: 1,
          description: item.name,
          amount: item.price[:amount].to_i,
          quantity: 1
        }
      end
      items
    end

    def generate_checkout_payload(_amount, reference, sender, items)
      url_redirect = Setting.get('pagseguro_url_redirect')
      url_notify = Setting.get('pagseguro_url_notify')

      body = {
        reference_id: reference,
        expiration_date: (Time.now + 3600).strftime('%Y-%m-%dT%H:%M:%S%:z'),
        customer: {
          tax_id: sender[:cpf],
          name: sender[:name],
          email: sender[:email]
        },
        customer_modifiable: true,
        payment_methods: [
          {
            type: 'credit_card',
            brands: [
              'mastercard'
            ]
          },
          {
            type: 'credit_card',
            brands: [
              'visa'
            ]
          },
          {
            type: 'debit_card',
            brands: [
              'visa'
            ]
          },
          # {
          #   type: 'PIX'
          # },
          {
            type: 'BOLETO'
          }
        ],
        redirect_url: url_redirect,
        payment_notification_urls: [
          url_notify
        ]
      }
      body[:items] = items.map do |item|
        {
          reference_id: item[:id],
          name: item[:description],
          quantity: item[:quantity],
          unit_amount: item[:amount]
        }
      end

      body
    end

    def create_checkout(payload)
      email = Setting.get('pagseguro_email')
      token = Setting.get('pagseguro_token')
      is_production = Setting.get('pagseguro_production')

      endpoint = if is_production
                   'https://api.pagseguro.com/checkouts'
                 else
                   'https://sandbox.api.pagseguro.com/checkouts'
                 end

      uri = URI(endpoint)
      puts uri

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri)

        response = http.request request
        request['Content-Type'] = 'application/json'
        request['Authorization'] = "Bearer #{token}"

        puts payload

        request.body = payload
        response = http.request request

        if response.code.to_i == 201
          puts "RESPONSE #{response.body}"
          result = JSON.parse(response.body)
          pay_url = result['links'].find { |link| link['rel'] == 'PAY' }['href']
          { url: pay_url, code: pay_url.match(/code=([^&]+)/)[1] }
        else
          puts "Erro na requisição POST. Código de resposta: #{response.code}"
          puts "Erro na requisição POST. Código de resposta: #{response.body}"
          { error: response.body }
        end
      end
    end

    def get_info_from_webhook_response(payload)
      data = JSON.parse(payload, symbolize_names: true)
      charge_data = data[:charges][0]
      return {
        order_id: data[:id],
        reference_id: data[:reference_id],
        status: charge_data[:status],
        paid_at: charge_data[:paid_at],
        method: charge_data[:payment_method][:type],
        nsu: charge_data[:payment_response][:raw_data][:nsu]
      }
    end

    def get_transaction_by_code(code)
      email = Setting.get('pagseguro_email')
      token = Setting.get('pagseguro_token')
      is_production = Setting.get('pagseguro_production')

      endpoint = if is_production
                   'https://ws.pagseguro.uol.com.br/v3/transactions/notifications/'
                 else
                   'https://ws.sandbox.pagseguro.uol.com.br/v3/transactions/notifications/'
                 end

      uri = URI(endpoint)
      puts uri

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(uri.path.concat("#{code}?email=#{email}&token=#{token}"))

        response = http.request request

        if response.code.to_i == 200
          puts "RTESPONSE #{response.body}"
          extract_status_and_code_from_xml(response.body)
        else
          puts "Erro na requisição GET. Código de resposta: #{response.code}"
          puts "Erro na requisição GET. Código de resposta: #{response.body}"
          { error: response.body }
        end
      end
    end

    private

    def extract_status_and_code_from_xml(xml)
      status = xml.match(%r{<status>(.*?)</status>}m)&.captures&.first
      code = xml.match(%r{<reference>(.*?)</reference>}m)&.captures&.first

      if status && code
        { status: status, code: code }

      else
        nil
      end
    end
  end
end
