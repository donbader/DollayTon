class AddParentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :parent, index: true, foreign_key: { to_table: :orders }
  end
end
