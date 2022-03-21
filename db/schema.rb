# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171223131057) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "indicators_point_and_figures", force: :cascade do |t|
    t.string "instrument", null: false
    t.integer "granularity", null: false
    t.integer "box_size", null: false
    t.integer "reversal_amount", null: false
    t.integer "trend", null: false
    t.integer "trend_length", null: false
    t.integer "pattern"
    t.datetime "candle_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "xo", null: false
    t.integer "xo_length", null: false
    t.integer "xo_box_price", null: false
    t.integer "trend_box_price", null: false
    t.integer "high_low_close", null: false
    t.index ["instrument", "granularity", "box_size", "reversal_amount", "high_low_close", "candle_at", "xo", "xo_box_price", "xo_length", "trend", "trend_box_price", "trend_length"], name: "index_indicators_point_and_figures_unique", unique: true
    t.index ["trend_length"], name: "index_indicators_point_and_figures_on_trend_length"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "authentication_token", limit: 30
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
