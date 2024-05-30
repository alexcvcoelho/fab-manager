# frozen_string_literal: true

require 'payment/helper'

# PayZen payement gateway
module Getnet; end

## Provides various methods around the Getnet payment gateway
class Getnet::Helper < Payment::Helper
  class << self
    ## Is the Getnet gateway enabled?
    def enabled?
      return false unless Setting.get('online_payment_module')
      return false unless Setting.get('payment_gateway') == 'getnet'
      res = true
      %w[getnet_token getnet_seller_id getnet_client_id getnet_client_secret].each do |pg_setting|
        res = false unless Setting.get(pg_setting).present?
      end
      res
    end

    def card_token(card_number, customer_id)
      {
        card_number: card_number.gsub(" ", ""),
        customer_id: customer_id.to_s
      }
    end

    def human_error(error)
      I18n.t('errors.messages.gateway_error', **{ MESSAGE: error.message })
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
