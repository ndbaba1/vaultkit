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

ActiveRecord::Schema[7.1].define(version: 2026_01_02_190529) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.string "name", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_access_tokens_on_organization_id"
    t.index ["token_digest"], name: "index_access_tokens_on_token_digest", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "actor_id"
    t.string "event", null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["event"], name: "index_audit_logs_on_event"
    t.index ["occurred_at"], name: "index_audit_logs_on_occurred_at"
    t.index ["organization_id"], name: "index_audit_logs_on_organization_id"
  end

  create_table "data_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "engine", null: false
    t.string "mode", null: false
    t.string "provider"
    t.text "config_encrypted"
    t.text "local_credentials_encrypted"
    t.uuid "org_id", null: false
    t.uuid "created_by", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["engine"], name: "index_data_sources_on_engine"
    t.index ["mode"], name: "index_data_sources_on_mode"
    t.index ["org_id", "name"], name: "index_data_sources_on_org_id_and_name", unique: true
    t.index ["provider"], name: "index_data_sources_on_provider"
  end

  create_table "datasources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.citext "name", null: false
    t.string "engine", null: false
    t.text "username_encrypted"
    t.text "password_encrypted"
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_datasources_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_datasources_on_organization_id"
  end

  create_table "grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "user_id", null: false
    t.string "dataset", null: false
    t.jsonb "fields", default: [], null: false
    t.jsonb "mask_fields", default: [], null: false
    t.string "decision", null: false
    t.string "policy_id"
    t.string "reason"
    t.integer "ttl_seconds", null: false
    t.datetime "expires_at", null: false
    t.string "session_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ref", null: false
    t.jsonb "aql", null: false
    t.string "fingerprint"
    t.index ["aql"], name: "index_grants_on_aql", using: :gin
    t.index ["expires_at"], name: "index_grants_on_expires_at"
    t.index ["fingerprint"], name: "index_grants_on_fingerprint"
    t.index ["organization_id", "dataset"], name: "index_grants_on_organization_id_and_dataset"
    t.index ["organization_id"], name: "index_grants_on_organization_id"
    t.index ["ref"], name: "index_grants_on_ref", unique: true
    t.index ["user_id"], name: "index_grants_on_user_id"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "domain"
    t.string "plan", default: "free"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["domain"], name: "index_organizations_on_domain", unique: true
    t.index ["metadata"], name: "index_organizations_on_metadata", using: :gin
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "policy_approvals", force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "requester_id", null: false
    t.uuid "approver_id"
    t.string "dataset", null: false
    t.jsonb "fields", default: [], null: false
    t.string "approver_role"
    t.string "reason"
    t.string "state", default: "pending", null: false
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "grant_id"
    t.jsonb "aql", null: false
    t.string "aql_fingerprint", null: false
    t.index ["approver_id"], name: "index_policy_approvals_on_approver_id"
    t.index ["aql"], name: "index_policy_approvals_on_aql", using: :gin
    t.index ["grant_id"], name: "index_policy_approvals_on_grant_id"
    t.index ["organization_id", "requester_id", "aql_fingerprint"], name: "uniq_pending_policy_approvals_by_fingerprint", unique: true, where: "((state)::text = 'pending'::text)"
    t.index ["organization_id", "requester_id", "dataset", "approver_role", "fields"], name: "uniq_pending_policy_approvals", unique: true, where: "((state)::text = 'pending'::text)"
    t.index ["organization_id", "state"], name: "index_policy_approvals_on_organization_id_and_state"
    t.index ["organization_id"], name: "index_policy_approvals_on_organization_id"
    t.index ["requester_id"], name: "index_policy_approvals_on_requester_id"
  end

  create_table "policy_bundle_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "created_by_id"
    t.string "bundle_version", null: false
    t.string "checksum", null: false
    t.jsonb "bundle_json", null: false
    t.string "state", default: "uploaded", null: false
    t.datetime "activated_at"
    t.string "source_repo"
    t.string "source_ref"
    t.string "source_commit_sha"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_policy_bundle_versions_on_created_by_id"
    t.index ["organization_id", "bundle_version"], name: "idx_on_organization_id_bundle_version_3f63e23f48", unique: true
    t.index ["organization_id", "checksum"], name: "index_policy_bundle_versions_on_organization_id_and_checksum", unique: true
    t.index ["organization_id", "state"], name: "index_policy_bundle_versions_on_organization_id_and_state"
    t.index ["organization_id"], name: "index_policy_bundle_versions_on_organization_id"
  end

  create_table "scan_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "user_id", null: false
    t.string "datasource_name", null: false
    t.string "status", default: "queued", null: false
    t.jsonb "raw_schema", default: {}, null: false
    t.jsonb "classified_schema", default: {}, null: false
    t.jsonb "diff", default: {}, null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "datasource_name", "created_at"], name: "idx_on_organization_id_datasource_name_created_at_fe59c42a70"
    t.index ["organization_id"], name: "index_scan_runs_on_organization_id"
    t.index ["user_id"], name: "index_scan_runs_on_user_id"
  end

  create_table "schema_registry_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.string "dataset_name", null: false
    t.string "datasource_name", null: false
    t.jsonb "fields", default: [], null: false
    t.string "source", null: false
    t.string "bundle_version"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "dataset_name"], name: "idx_schema_registry_entries_org_dataset", unique: true
    t.index ["organization_id", "datasource_name"], name: "idx_on_organization_id_datasource_name_25c685764d"
    t.index ["organization_id"], name: "index_schema_registry_entries_on_organization_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password"
    t.string "full_name"
    t.string "role", default: "member"
    t.uuid "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti"
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "audit_logs", "organizations"
  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "datasources", "organizations"
  add_foreign_key "grants", "organizations"
  add_foreign_key "grants", "users"
  add_foreign_key "policy_approvals", "grants"
  add_foreign_key "policy_approvals", "organizations"
  add_foreign_key "policy_approvals", "users", column: "approver_id"
  add_foreign_key "policy_approvals", "users", column: "requester_id"
  add_foreign_key "policy_bundle_versions", "organizations"
  add_foreign_key "policy_bundle_versions", "users", column: "created_by_id"
  add_foreign_key "scan_runs", "organizations"
  add_foreign_key "scan_runs", "users"
  add_foreign_key "schema_registry_entries", "organizations"
  add_foreign_key "users", "organizations"
end
