# frozen_string_literal: true

json.result @result.as_json.merge(id: @id)
json.orderId @id
