# frozen_string_literal: true

class GetnetTransaction < ApplicationRecord
  belongs_to :invoice, optional: true
end
