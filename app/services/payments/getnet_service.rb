# frozen_string_literal: true

# Provides methods for pay cart by PayZen
class Payments::GetnetService
  require 'getnet/helper'
  require 'getnet/card'
  include Payments::PaymentConcern

  def payment(order, coupon_code)
    amount = debit_amount(order, coupon_code)

    raise Cart::ZeroPriceError if amount.zero?

    id = GetNet::Helper.generate_ref(order, order.statistic_profile.user.id)

    client = Getnet::Card.new
    result = client.create_payment(seller_id: Setting.get('getnet_seller_id'),
                                   amount: amount,
                                   order: GetNet::Helper.generate_order(id),
                                   customer: GetNet::Helper.generate_customer(order.statistic_profile.user.id),
                                   device: GetNet::Helper.generate_device(request),
                                   credit: GetNet::Helper.generate_credit(order.statistic_profile.user.id, order))
    { order: order, payment: result }
  end

  def confirm_payment(order, coupon_code, payment_id)
    o = payment_success(order, coupon_code, 'card', payment_id, 'GetNet::Order')
    { order: o }
  end
end
