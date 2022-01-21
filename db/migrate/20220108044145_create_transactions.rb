class CreateTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      t.column :t_hash, :string, null: true
      t.datetime :time
      t.string :giver

      t.index :t_hash, unique: true

      t.timestamps
    end
  end
end
