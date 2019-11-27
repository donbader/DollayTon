class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.string :exchange
      t.decimal :balance, precision: 16, scale: 2
      t.timestamps
    end
  end
end
