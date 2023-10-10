class CreatePagseguroIntent < ActiveRecord::Migration[7.0]
  def change
    create_table :pagseguro_intents do |t|
      t.string :reference_code
      t.string :payment_code
      t.text :shopping_cart
      t.string :status
      
      t.timestamps
    end
  end
end
