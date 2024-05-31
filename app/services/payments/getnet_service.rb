# frozen_string_literal: true

# Provides methods for pay cart by PayZen
class Payments::GetnetService
  require 'getnet/helper'
  require 'getnet/card'
  require 'pay_zen/charge'
  require 'pay_zen/service'
  include Payments::PaymentConcern

  def payment(order, coupon_code)
    amount = debit_amount(order, coupon_code)

    raise Cart::ZeroPriceError if amount.zero?

    id = Getnet::Helper.generate_ref(order, order.statistic_profile.user.id)

    client = Getnet::Card.new
    result = client.create_payment(amount: amount,
                                   order_id: id,
                                   customer: Getnet::Helper.generate_customer(order.statistic_profile.user.id, order))
    { order: order, payment: result }
  end

  def confirm_payment(order, coupon_code, payment_id)
    client = PayZen::Order.new
    payzen_order = client.get(payment_id, operation_type: 'DEBIT')

    if payzen_order['answer']['transactions'].any? { |transaction| transaction['status'] == 'PAID' }
      o = payment_success(order, coupon_code, 'card', payment_id, 'PayZen::Order')
      { order: o }
    else
      order.update(state: 'payment_failed')
      { order: order, payment: { error: { statusText: payzen_order['answer'] } } }
    end
  end
end
