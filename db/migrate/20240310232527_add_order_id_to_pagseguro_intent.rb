class AddOrderIdToPagseguroIntent < ActiveRecord::Migration[7.0]
  def change
    add_column :pagseguro_intents, :order_id, :string
  end
end
