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

ActiveRecord::Schema[8.0].define(version: 2025_04_25_075132) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "hackathon_insights", force: :cascade do |t|
    t.text "content"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hackathon_id", null: false
    t.index ["hackathon_id"], name: "index_hackathon_insights_on_hackathon_id"
  end

  create_table "hackathons", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.date "start_date"
    t.date "end_date"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_hackathons_on_name", unique: true
  end

  create_table "judging_criterions", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "weight", precision: 5, scale: 2, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hackathon_id", null: false
    t.index ["hackathon_id", "name"], name: "index_judging_criterions_on_hackathon_id_and_name", unique: true
    t.index ["hackathon_id"], name: "index_judging_criterions_on_hackathon_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.string "team_name", null: false
    t.string "filename", null: false
    t.string "file_type", null: false
    t.string "source_url", null: false
    t.text "raw_text"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "project"
    t.text "summary"
    t.bigint "hackathon_id", null: false
    t.index ["file_type"], name: "index_submissions_on_file_type"
    t.index ["hackathon_id", "team_name"], name: "index_submissions_on_hackathon_id_and_team_name"
    t.index ["hackathon_id"], name: "index_submissions_on_hackathon_id"
    t.index ["status"], name: "index_submissions_on_status"
    t.index ["team_name"], name: "index_submissions_on_team_name"
  end

  create_table "team_blogs", force: :cascade do |t|
    t.string "team_name"
    t.text "content"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hackathon_id", null: false
    t.index ["hackathon_id", "team_name"], name: "index_team_blogs_on_hackathon_id_and_team_name", unique: true
    t.index ["hackathon_id"], name: "index_team_blogs_on_hackathon_id"
  end

  create_table "team_evaluations", force: :cascade do |t|
    t.string "team_name", null: false
    t.jsonb "scores", default: {}, null: false
    t.decimal "total_score", precision: 5, scale: 2
    t.text "comments"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hackathon_id", null: false
    t.index ["hackathon_id", "team_name"], name: "index_team_evaluations_on_hackathon_id_and_team_name", unique: true
    t.index ["hackathon_id"], name: "index_team_evaluations_on_hackathon_id"
  end

  create_table "team_summaries", force: :cascade do |t|
    t.string "team_name"
    t.text "content"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hackathon_id", null: false
    t.index ["hackathon_id", "team_name"], name: "index_team_summaries_on_hackathon_id_and_team_name", unique: true
    t.index ["hackathon_id"], name: "index_team_summaries_on_hackathon_id"
  end

  add_foreign_key "hackathon_insights", "hackathons"
  add_foreign_key "judging_criterions", "hackathons"
  add_foreign_key "submissions", "hackathons"
  add_foreign_key "team_blogs", "hackathons"
  add_foreign_key "team_evaluations", "hackathons"
  add_foreign_key "team_summaries", "hackathons"
end
