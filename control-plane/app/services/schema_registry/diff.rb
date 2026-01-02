# frozen_string_literal: true

module SchemaRegistry
  class Diff
    # returns a structured diff:
    # {
    #   "datasets": [
    #     { "name": "...", "changes": { "added_fields": [...], "removed_fields": [...], "changed_fields": [...] } }
    #   ]
    # }
    def self.compute(current_entries:, scanned_datasets:)
      current_by_dataset =
        current_entries.index_by(&:dataset_name)

      out = { "datasets" => [] }

      scanned_datasets.each do |sd|
        name = sd.fetch("name")
        scanned_fields = normalize_fields(sd.fetch("fields"))
        current = current_by_dataset[name]

        current_fields = current ? normalize_fields(current.fields) : []

        out["datasets"] << {
          "name" => name,
          "datasource" => sd["datasource"],
          "changes" => diff_fields(current_fields, scanned_fields)
        }
      end

      out
    end

    def self.diff_fields(current_fields, scanned_fields)
      cur = current_fields.index_by { _1["name"] }
      scn = scanned_fields.index_by { _1["name"] }

      added = (scn.keys - cur.keys).map { |k| scn[k] }
      removed = (cur.keys - scn.keys).map { |k| cur[k] }

      changed = (cur.keys & scn.keys).filter_map do |k|
        next if cur[k] == scn[k]
        { "name" => k, "from" => cur[k], "to" => scn[k] }
      end

      {
        "added_fields" => added,
        "removed_fields" => removed,
        "changed_fields" => changed
      }
    end

    def self.normalize_fields(fields)
      Array(fields).map do |f|
        {
          "name"        => f["name"]&.to_s || f[:name]&.to_s,
          "type"        => f["type"]&.to_s || f[:type]&.to_s,
          "sensitivity" => f["sensitivity"]&.to_s || f[:sensitivity]&.to_s,
          "tags"        => Array(f["tags"] || f[:tags])
                             .map(&:to_s)
                             .sort
        }
      end.sort_by { |f| f["name"] }
    end    

    private_class_method :diff_fields, :normalize_fields
  end
end
