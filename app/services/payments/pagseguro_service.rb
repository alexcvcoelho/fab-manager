# frozen_string_literal: true

# Provides methods for pay cart by PagSeguro
class Payments::PagseguroService
  require 'pagseguro/helper'
  include Payments::PaymentConcern

  def payment(order, coupon_code)
    amount = debit_amount(order, coupon_code)

    raise Cart::ZeroPriceError if amount.zero?

    @id = PagSeguro::Helper.generate_ref(order, order.statistic_profile.user.id)

    payload = PagSeguro::Helper.generate_checkout_payload(
      amount,
      @id,
      PagSeguro::Helper.generate_sender_v2(order.statistic_profile.user.id),
      PagSeguro::Helper.generate_items_v2(order, order.statistic_profile.user.id)
    )


    result = PagSeguro::Helper.create_checkout(JSON.generate(payload))
    data = { coupon_code: coupon_code, customer_id: order.statistic_profile.user.id, token: order.token }

    @pagseguro_intent = PagseguroIntent.new(reference_code: @id, payment_code: result[:code], shopping_cart: data.to_json, status: "pending", transaction_type: "store")
    @pagseguro_intent.save
    
    { order: order, payment: result}
  end

  def confirm_payment(order, coupon_code, payment_id, payment_method)
    o = payment_success(order, coupon_code, payment_method, payment_id, 'PagSeguro::Order')
    { order: o }
  end
end
