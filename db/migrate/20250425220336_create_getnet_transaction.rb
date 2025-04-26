class CreateGetnetTransaction < ActiveRecord::Migration[7.0]
  def change
    create_table :getnet_transactions do |t|
      t.string :order_id
      t.references :invoice, foreign_key: true, null: true
      t.jsonb :payload
      t.timestamps
    end
  end
end
