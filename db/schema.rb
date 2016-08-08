# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160803230946) do

  create_table "collections", force: :cascade do |t|
    t.string   "druid",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "collections", ["druid"], name: "index_collections_on_druid"

  create_table "collections_purls", id: false, force: :cascade do |t|
    t.integer "purl_id"
    t.integer "collection_id"
  end

  add_index "collections_purls", ["collection_id"], name: "index_collections_purls_on_collection_id"
  add_index "collections_purls", ["purl_id"], name: "index_collections_purls_on_purl_id"

  create_table "purls", force: :cascade do |t|
    t.string   "druid",       null: false
    t.string   "title"
    t.string   "object_type"
    t.string   "catkey"
    t.datetime "deleted_at"
    t.datetime "indexed_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "purls", ["deleted_at"], name: "index_purls_on_deleted_at"
  add_index "purls", ["druid"], name: "index_purls_on_druid"
  add_index "purls", ["indexed_at"], name: "index_purls_on_indexed_at"

  create_table "release_tags", force: :cascade do |t|
    t.string   "name",         null: false
    t.boolean  "release_type", null: false
    t.integer  "purl_id",      null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "release_tags", ["purl_id"], name: "index_release_tags_on_purl_id"
  add_index "release_tags", ["release_type"], name: "index_release_tags_on_release_type"

  create_table "run_logs", force: :cascade do |t|
    t.integer  "total_druids"
    t.integer  "num_errors"
    t.string   "finder_filename"
    t.string   "note"
    t.datetime "started"
    t.datetime "ended"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

end
