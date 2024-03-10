class AddPayloadToPagseguroIntent < ActiveRecord::Migration[7.0]
  def change
    add_column :pagseguro_intents, :payload, :text
  end
end
