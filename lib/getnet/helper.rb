# frozen_string_literal: true

require 'payment/helper'

# PayZen payement gateway
module GetNet; end

## Provides various methods around the Getnet payment gateway
class GetNet::Helper < Payment::Helper
  class << self
    ## Is the Getnet gateway enabled?
    def enabled?
      return true
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'getnet'
      res = true
      %w[getnet_token getnet_seller_id getnet_client_id getnet_client_secret].each do |pg_setting|
        res = false unless Setting.get(pg_setting).present?
      end
      res
    end

    def human_error(error)
      I18n.t('errors.messages.gateway_error', **{ MESSAGE: error.message })
    end

    def card_token(card_number, customer_id)
      {
        card_number: card_number.gsub(" ", ""),
        customer_id: customer_id.to_s
      }
    end

    def generate_customer(customer_id)
      customer = User.find(customer_id)

      {
        customer_id: customer_id.to_s,
        first_name: customer.statistic_profile.user.first_name,
        last_name: customer.statistic_profile.user.last_name,
        email: customer.statistic_profile.user.email,
        document_type: customer.organization? ? 'CNPJ' : 'CPF',
        document_number: customer.profile.cpf,
        phone_number: customer.profile.phone,
        billing_address: {
          street: customer.profile.street,
          number: customer.profile.number,
          complement: customer.profile.complement,
          district: customer.profile.neighborhood,
          city: customer.profile.city,
          state: customer.profile.state,
          country: 'Brasil',
          postal_code: customer.profile.zipcode
        }
      }
    end

    def generate_order(order_id)
      {
        order_id: order_id.to_s,
        sales_tax: 0,
        product_type: 'service',
      }
    end

    def generate_device(request)
      {
        ip_address: request.remote_ip,
        device_id: request.user_agent
      }
    end

    def generate_credit(card)
      {
        delayed: false,
        pre_authorization: false,
        save_card_data: false,
        transaction_type: 'FULL',
        number_installments: 1,
        soft_descriptor: 'Fablab Casa Firjan',
        card: {
          number_token: card['token'],
          cardholder_name: card['name'],
          security_code: card['cvv'],
          expiration_month: card['expiration'].split('/')[0],
          expiration_year: card['expiration'].split('/')[1]
        }
      }
    end

    ## generate an unique string reference for the content of a cart
    def generate_ref(cart_items, customer)
      require 'sha3'

      content = { cart_items: cart_items, customer: customer }.to_json + Time.current.iso8601
      # It's safe to truncate a hash. See https://crypto.stackexchange.com/questions/74646/sha3-255-one-bit-less
      SHA3::Digest.hexdigest(:sha224, content)[0...24]
    end

  end
end
