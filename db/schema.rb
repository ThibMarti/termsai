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

ActiveRecord::Schema[8.1].define(version: 2026_07_21_081021) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "raw_text"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "offers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "price_cents"
    t.integer "tokens_amount"
    t.datetime "updated_at", null: false
  end

  create_table "orders", force: :cascade do |t|
    t.integer "amount_cents"
    t.string "checkout_session_id"
    t.datetime "created_at", null: false
    t.bigint "offer_id", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["offer_id"], name: "index_orders_on_offer_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "scan_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "document_id", null: false
    t.integer "score"
    t.datetime "updated_at", null: false
    t.string "verdict"
    t.index ["document_id"], name: "index_scan_results_on_document_id"
  end

  create_table "scans", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.jsonb "full_report", default: {}
    t.integer "risk_score"
    t.string "site_name"
    t.string "status", default: "processing"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "tokens", force: :cascade do |t|
    t.integer "balance", default: 1, null: false
    t.datetime "created_at", null: false
    t.integer "token_amount", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_tokens_on_user_id"
  end

  create_table "user_scans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "scan_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["scan_id"], name: "index_user_scans_on_scan_id"
    t.index ["user_id"], name: "index_user_scans_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "extension_token"
    t.string "first_name"
    t.string "last_name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["extension_token"], name: "index_users_on_extension_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "orders", "offers"
  add_foreign_key "orders", "users"
  add_foreign_key "scan_results", "documents"
  add_foreign_key "tokens", "users"
  add_foreign_key "user_scans", "scans"
  add_foreign_key "user_scans", "users"
end
