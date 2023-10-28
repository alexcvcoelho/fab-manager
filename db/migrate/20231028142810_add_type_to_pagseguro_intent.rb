class AddTypeToPagseguroIntent < ActiveRecord::Migration[7.0]
  def change
    add_column :pagseguro_intents, :transaction_type, :string
  end
end
