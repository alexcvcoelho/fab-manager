require 'getnet/client'

# Authentication/* endpoints of the Getnet REST API
class Getnet::Card < Getnet::Client
  def initialize(base_url: nil, client_id: nil, client_secret: nil, seller_id: nil)
    super(base_url: nil, client_id: nil, client_secret: nil, seller_id: nil)
  end

  def create_token(payload)
    post('/v1/tokens/card', payload)
  end

  def create_payment(seller_id: nil,
                     amount: 0,
                     currency: 'BRL',
                     order: nil,
                     customer: nil,
                     device: nil,
                     credit: nil)
    post('/v1/payments/credit',
         seller_id: seller_id,
         amount: amount,
         currency: currency,
         order: order,
         customer: customer,
         device: device,
         credit: credit)
  end
end