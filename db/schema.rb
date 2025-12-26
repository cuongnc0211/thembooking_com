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

ActiveRecord::Schema[8.1].define(version: 2025_12_06_171152) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "booking_services", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.bigint "service_id", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "service_id"], name: "index_booking_services_on_booking_id_and_service_id", unique: true
    t.index ["booking_id"], name: "index_booking_services_on_booking_id"
    t.index ["service_id"], name: "index_booking_services_on_service_id"
  end

  create_table "booking_slots", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.bigint "slot_id", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "slot_id"], name: "index_booking_slots_on_booking_and_slot", unique: true
    t.index ["booking_id"], name: "index_booking_slots_on_booking_id"
    t.index ["slot_id"], name: "index_booking_slots_on_slot_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "customer_email", limit: 255
    t.string "customer_name", limit: 100, null: false
    t.string "customer_phone", limit: 20, null: false
    t.text "notes"
    t.datetime "scheduled_at", null: false
    t.integer "source", default: 0, null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "scheduled_at"], name: "index_bookings_on_business_id_and_scheduled_at"
    t.index ["business_id", "status"], name: "index_bookings_on_business_id_and_status"
    t.index ["business_id"], name: "index_bookings_on_business_id"
    t.index ["customer_email"], name: "index_bookings_on_customer_email"
    t.index ["customer_phone"], name: "index_bookings_on_customer_phone"
  end

  create_table "businesses", force: :cascade do |t|
    t.string "address"
    t.string "business_type", default: "barber", null: false
    t.integer "capacity", default: 1, null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "VND", null: false
    t.text "description"
    t.jsonb "landing_page_config", default: {}
    t.string "name", null: false
    t.jsonb "operating_hours", default: {}
    t.string "phone"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["slug"], name: "index_businesses_on_slug", unique: true
    t.index ["user_id"], name: "index_businesses_on_user_id"
    t.index ["user_id"], name: "index_businesses_on_user_id_unique", unique: true
  end

  create_table "services", force: :cascade do |t|
    t.boolean "active", default: true
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "VND", null: false
    t.text "description"
    t.integer "duration_minutes", null: false
    t.string "name", limit: 100, null: false
    t.integer "position", default: 0
    t.integer "price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "active"], name: "index_services_on_business_id_and_active"
    t.index ["business_id", "position"], name: "index_services_on_business_id_and_position"
    t.index ["business_id"], name: "index_services_on_business_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "slots", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.integer "capacity", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.datetime "end_time", null: false
    t.integer "original_capacity", default: 0, null: false
    t.datetime "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "date"], name: "index_slots_on_business_and_date"
    t.index ["business_id", "start_time"], name: "index_slots_on_business_and_start_time", unique: true
    t.index ["business_id"], name: "index_slots_on_business_id"
    t.index ["date"], name: "index_slots_on_date"
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "email_confirmation_sent_at"
    t.string "email_confirmation_token"
    t.datetime "email_confirmed_at"
    t.string "name"
    t.datetime "onboarding_completed_at"
    t.integer "onboarding_step", default: 1, null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.boolean "profile_completed", default: false
    t.string "time_zone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["email_confirmation_token"], name: "index_users_on_email_confirmation_token", unique: true
    t.index ["email_confirmed_at"], name: "index_users_on_email_confirmed_at"
    t.index ["onboarding_completed_at"], name: "index_users_on_onboarding_completed_at"
    t.index ["onboarding_step"], name: "index_users_on_onboarding_step"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "booking_services", "bookings"
  add_foreign_key "booking_services", "services"
  add_foreign_key "booking_slots", "bookings"
  add_foreign_key "booking_slots", "slots"
  add_foreign_key "bookings", "businesses"
  add_foreign_key "businesses", "users"
  add_foreign_key "services", "businesses"
  add_foreign_key "sessions", "users"
  add_foreign_key "slots", "businesses"
end
