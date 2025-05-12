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

ActiveRecord::Schema[8.0].define(version: 2025_05_11_054513) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "municipalities", force: :cascade do |t|
    t.bigint "prefecture_id", null: false
    t.string "name_kanji", limit: 50, null: false
    t.string "name_kana", limit: 50, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prefecture_id", "name_kanji"], name: "index_municipalities_on_prefecture_id_and_name_kanji", unique: true
    t.index ["prefecture_id"], name: "index_municipalities_on_prefecture_id"
  end

  create_table "prefectures", force: :cascade do |t|
    t.string "name_kanji", limit: 50, null: false
    t.string "name_kana", limit: 50, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_kana"], name: "index_prefectures_on_name_kana", unique: true
    t.index ["name_kanji"], name: "index_prefectures_on_name_kanji", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "prefecture_id", null: false
    t.bigint "municipality_id", null: false
    t.string "nickname", null: false
    t.string "identifier", null: false
    t.text "bio"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_profiles_on_identifier", unique: true
    t.index ["municipality_id"], name: "index_profiles_on_municipality_id"
    t.index ["prefecture_id"], name: "index_profiles_on_prefecture_id"
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "change_password_token"
    t.datetime "change_password_sent_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["change_password_token"], name: "index_users_on_change_password_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "municipalities", "prefectures"
  add_foreign_key "profiles", "municipalities"
  add_foreign_key "profiles", "prefectures"
  add_foreign_key "profiles", "users"
end
