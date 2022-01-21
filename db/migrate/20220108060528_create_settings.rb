class CreateSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :settings do |t|
      t.text :last_transaction

      t.timestamps
    end
  end
end
