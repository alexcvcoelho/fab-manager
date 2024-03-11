class PagseguroIntent < ApplicationRecord
    validates :reference_code, presence: true
    validates :payment_code, presence: true
    validates :shopping_cart, presence: true
    validates :status, presence: true
    validates :transaction_type, presence: true

    def payment_method?
        data = payload_data
        if (data == nil) 
            return nil
        end
        if (data[:charges][0][:payment_method][:type] == 'CREDIT_CARD')
            return 'card'
        elsif (data[:charges][0][:payment_method][:type] == 'BOLETO')
            return 'boleto'
        end
    end

    def nsu
        data = payload_data
        if (data == nil) 
            return nil
        end
        if (payment_method == 'boleto')
            return nil
        end
        return data[:charges][0][:payment_response][:raw_data][:nsu]
    end

    def order_id
        data = payload_data
        if (data == nil) 
            return nil
        end
        return data[:id]
    end
    
    def paid_at
        data = payload_data
        if (data == nil) 
            return nil
        end
        return data[:charges][0][:paid_at]
    end

    private

    def payload_data
        if (payload == nil) 
            return nil
        end
        JSON.parse(payload, symbolize_names: true)
    end
end
