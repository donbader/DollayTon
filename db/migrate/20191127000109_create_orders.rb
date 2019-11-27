class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.references :account, index: true, foreign_key: true
      t.string :exchange
      t.string :type
      t.decimal :amount, precision: 16, scale: 2
      t.decimal :price, precision: 16, scale: 2
      t.string :status
      t.timestamps
    end
  end
end
