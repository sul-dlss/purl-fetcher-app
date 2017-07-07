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

ActiveRecord::Schema.define(version: 20170321232801) do

  create_table "collections", force: :cascade do |t|
    t.string "druid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["druid"], name: "index_collections_on_druid", unique: true
  end

  create_table "collections_purls", id: false, force: :cascade do |t|
    t.integer "purl_id"
    t.integer "collection_id"
    t.index ["collection_id"], name: "index_collections_purls_on_collection_id"
    t.index ["purl_id"], name: "index_collections_purls_on_purl_id"
  end

  create_table "listener_logs", force: :cascade do |t|
    t.integer "process_id", null: false
    t.datetime "started_at", null: false
    t.datetime "active_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["process_id"], name: "index_listener_logs_on_process_id"
    t.index ["started_at"], name: "index_listener_logs_on_started_at"
  end

  create_table "purls", force: :cascade do |t|
    t.string "druid", null: false
    t.string "object_type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "published_at"
    t.text "title"
    t.string "catkey"
    t.index ["deleted_at"], name: "index_purls_on_deleted_at"
    t.index ["druid"], name: "index_purls_on_druid", unique: true
    t.index ["object_type"], name: "index_purls_on_object_type"
    t.index ["published_at", "deleted_at"], name: "index_purls_on_published_at_and_deleted_at"
    t.index ["published_at"], name: "index_purls_on_published_at"
    t.index ["updated_at"], name: "index_purls_on_updated_at"
  end

  create_table "release_tags", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "release_type", null: false
    t.integer "purl_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "purl_id"], name: "index_release_tags_on_name_and_purl_id", unique: true
    t.index ["purl_id"], name: "index_release_tags_on_purl_id"
    t.index ["release_type"], name: "index_release_tags_on_release_type"
  end

  create_table "run_logs", force: :cascade do |t|
    t.integer "total_druids"
    t.integer "num_errors"
    t.string "finder_filename"
    t.string "note"
    t.datetime "started"
    t.datetime "ended"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
