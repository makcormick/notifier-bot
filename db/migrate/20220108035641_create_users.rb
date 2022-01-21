class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.integer :tg_id
      t.integer :chat_id
      t.string :first_name
      t.string :username
      t.boolean :notify_solution
      t.string :wallet
      t.string :locale
      t.integer :time_zone

      t.timestamps
    end
  end
end
