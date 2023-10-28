class PagseguroIntent < ApplicationRecord
    validates :reference_code, presence: true
    validates :payment_code, presence: true
    validates :shopping_cart, presence: true
    validates :status, presence: true
    validates :transaction_type, presence: true
end
