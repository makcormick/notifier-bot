# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_02_13_185402) do

  create_table "pools", force: :cascade do |t|
    t.integer "hashrate"
    t.integer "n_difficult"
    t.integer "last_sol_seq"
    t.datetime "last_solved_time"
    t.integer "total_miners"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "total_shares"
  end

  create_table "settings", force: :cascade do |t|
    t.text "last_transaction"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.string "t_hash"
    t.datetime "time"
    t.string "giver"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "pool_id"
    t.index ["pool_id"], name: "index_transactions_on_pool_id"
    t.index ["t_hash"], name: "index_transactions_on_t_hash", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.integer "tg_id"
    t.integer "chat_id"
    t.string "first_name"
    t.string "username"
    t.boolean "notify_solution"
    t.string "wallet"
    t.string "locale"
    t.integer "time_zone"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "transactions", "pools"
end
