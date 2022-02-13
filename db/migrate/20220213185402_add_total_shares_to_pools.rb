class AddTotalSharesToPools < ActiveRecord::Migration[6.1]
  def change
    add_column :pools, :total_shares, :string
  end
end
