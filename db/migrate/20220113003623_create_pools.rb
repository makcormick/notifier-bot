class CreatePools < ActiveRecord::Migration[6.1]
  def change
    create_table :pools do |t|
      t.integer :hashrate
      t.integer :n_difficult
      t.integer :last_sol_seq
      t.datetime :last_solved_time
      t.integer :total_miners

      t.timestamps
    end

    add_reference :transactions, :pool, index: true
    add_foreign_key :transactions, :pools
  end
end
