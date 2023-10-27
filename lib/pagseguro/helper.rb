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
    def generate_sender(customer_id)
      customer = User.find(customer_id)
      {
        name: customer.profile.full_name,
        email: customer.email,
        cpf: customer.profile.cpf,
        document: generate_document(customer)
      }        
    end

    ## generate hasgmap compatipble with pagseguro request
    def generate_items(cart_items, operator_id)
      operator = User.find(operator_id)
      items = Array.new
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
            description: "RESERVA FABLAB",
            amount: item.amount.to_i * 100,
            quantity: item.quantity.to_i
          }
        end
        return items
      end

      cart.items.map do |item|
        items << {
            id: 1,
            description: item.name,
            amount: item.price[:amount].to_i / 100.00,
            quantity: 1
        }
      end
      items
    end

    def generate_checkout_payload(amount, reference, sender, items, root_url)
      body = {
        reference_id: reference,
        expiration_date: (Time.now + 3600).strftime("%Y-%m-%dT%H:%M:%S%:z"),
        customer: {
          tax_id: sender[:cpf],
          name: sender[:name],
          email: sender[:email]
        },
        customer_modifiable: true,
        payment_methods: [
          {
            type: "credit_card",
            brands: [
              "mastercard"
            ]
          },
          {
            type: "credit_card",
            brands: [
              "visa"
            ]
          },
          {
            type: "debit_card",
            brands: [
              "visa"
            ]
          },
          {
            type: "PIX"
          },
          {
            type: "BOLETO"
          }
        ],
        redirect_url: root_url,
        return_url: root_url,
        notification_urls: [
          "#{root_url}api/pagseguro/notify"
        ]
      }
      body[:items] = items.map { |item| {
        reference_id: item[:id],
        name: item[:description],
        quantity: item[:quantity],
        unit_amount: item[:amount]
      }}

      body
    end

    def generate_payload(amount, reference, sender, items, root_url)
      body = "
        <checkout>
          <sender>
            <name>#{sender[:name]}</name>
            <email>#{sender[:email]}</email>
            <documents>
              <document>
                <type>#{sender[:document][:type]}</type>
                <value>#{sender[:document][:value]}</value>
              </document>
            </documents>
          </sender>
          <currency>BRL</currency>
          <items>"
          items.each do |item|
            body += "  <item>\n"
            body += "    <id>#{item[:id]}</id>\n"
            body += "    <description>#{item[:description]}</description>\n"
            body += "    <amount>#{format("%.2f", item[:amount])}</amount>\n"
            body += "    <quantity>#{item[:quantity]}</quantity>\n"
            body += "  </item>\n"
          end    

      body += "</items>
          <redirectURL>#{root_url}</redirectURL>
          <notificationURL>#{root_url}api/pagseguro/notify</notificationURL>
          <reference>#{reference}</reference>
          <receiver>
            <email>#{Setting.get('pagseguro_email')}</email>
          </receiver>
        </checkout>
      "
      body
    end

    def make_pagseguro_request(payload)
      email = Setting.get('pagseguro_email')
      token = Setting.get('pagseguro_token')
      is_production = Setting.get('pagseguro_production')

      if !is_production
        endpoint = "https://ws.sandbox.pagseguro.uol.com.br/v2/checkout"
        endpoint_redirect = "https://sandbox.pagseguro.uol.com.br/v2/checkout/payment.html"
      else
        endpoint = "https://ws.pagseguro.uol.com.br/v2/checkout"
        endpoint_redirect = "https://pagseguro.uol.com.br/v2/checkout/payment.html"
      end

      uri = URI(endpoint)
      puts uri

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri.path.concat("?email=#{email}&token=#{token}"))

        response = http.request request
        request['Content-Type'] = 'application/xml;charset=ISO-8859-1'
      
        request.body = payload
        response = http.request request

        if response.code.to_i == 200
          puts "RTESPONSE #{response.body}"
          code = extract_code_from_xml(response.body)
          { code: code, url: "#{endpoint_redirect}?code=#{code}" }
        else
          puts "Erro na requisição POST. Código de resposta: #{response.code}"
          puts "Erro na requisição POST. Código de resposta: #{response.body}"
          { error: response.body }
        end
      end
    end

    def create_checkout(payload)
      email = Setting.get('pagseguro_email')
      token = Setting.get('pagseguro_token')
      is_production = Setting.get('pagseguro_production')

      if !is_production
        endpoint = "https://sandbox.api.pagseguro.com/checkouts"
      else
        endpoint = "https://api.pagseguro.com/checkouts"
      end

      uri = URI(endpoint)
      puts uri

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri)

        response = http.request request
        request['Content-Type'] = "application/json"
        request['Authorization'] = "Bearer #{token}"

        puts payload

        request.body = payload
        response = http.request request

        if response.code.to_i == 201
          puts "RESPONSE #{response.body}"
          result = JSON.parse(response.body) 
          pay_url = result['links'].find { |link| link['rel'] == 'PAY' }['href']
          { url: pay_url, code: pay_url.match(/code=([^&]+)/)[1]}
        else
          puts "Erro na requisição POST. Código de resposta: #{response.code}"
          puts "Erro na requisição POST. Código de resposta: #{response.body}"
          { error: response.body }
        end
      end
    end

    def extract_code_from_xml(xml_string)
      code_start = xml_string.index("<code>")
      code_end = xml_string.index("</code>")
    
      if code_start && code_end
        code_start += "<code>".length
        code = xml_string[code_start...code_end]
        code.strip
      else
        nil
      end
    end

    def get_transaction_by_code(code)
      email = Setting.get('pagseguro_email')
      token = Setting.get('pagseguro_token')
      is_production = Setting.get('pagseguro_production')

      if !is_production
        endpoint = "https://ws.sandbox.pagseguro.uol.com.br/v3/transactions/notifications/"
      else
        endpoint = "https://ws.pagseguro.uol.com.br/v3/transactions/notifications/"
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

    def generate_document(customer)
      if customer.organization?
        return { type: "CNPJ", value: customer.profile.cpf }
      else
        return { type: "CPF", value: customer.profile.cpf }
      end
    end

    def extract_status_and_code_from_xml(xml)
      status = xml.match(/<status>(.*?)<\/status>/m)&.captures&.first
      code = xml.match(/<reference>(.*?)<\/reference>/m)&.captures&.first
    
      if status && code
        result = { status: status, code: code }
        return result
      else
        return nil
      end
    end
  end
end
