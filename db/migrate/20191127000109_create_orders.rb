class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.references :account, index: true, foreign_key: true
      t.string :exchange
      t.string :pair_name
      t.string :type
      t.boolean :direction, default: false
      t.decimal :quantity, precision: 16, scale: 2
      t.decimal :price, precision: 16, scale: 2
      t.string :status
      t.timestamps
    end

    add_reference :orders, :parent_order, index: true, foreign_key: { to_table: :orders }
  end
end
