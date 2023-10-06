# frozen_string_literal: true

# PagSeguro payement gateway
module PagSeguro; end

## Provides various methods around the PagSeguro payment gateway
class PagSeguro::Helper
  class << self
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
            amount: item.amount.to_i / 100.00,
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

    def generate_payload(amount, reference, sender, items)
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
          <redirectURL>https://fablab-hmg.casafirjan.com.br/</redirectURL>
          <reference>#{reference}</reference>
          <receiver>
            <email>#{Setting.get('pagseguro_email')}</email>
          </receiver>
        </checkout>
      "
      body
    end

    def make_pagseguro_request(payload)
      require 'net/http'
      require 'uri'

      email = Setting.get('pagseguro_email')
      token = Setting.get('pagseguro_token')
      endpoint = "https://ws.sandbox.pagseguro.uol.com.br/v2/checkout"
      endpoint_redirect = "https://sandbox.pagseguro.uol.com.br/v2/checkout/payment.html"

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

    private

    def generate_document(customer)
      if customer.organization?
        return { type: "CNPJ", value: customer.profile.cpf }
      else
        return { type: "CPF", value: customer.profile.cpf }
      end
    end
  end
end
