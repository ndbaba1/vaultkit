module Datasources
  class DatasetScanner
    def initialize(funl_client:, jwt_issuer:)
      @funl_client = funl_client
      @jwt_issuer  = jwt_issuer
    end

    def scan
      token = issue_internal_token

      tables = @funl_client.introspect_tables(
        bearer: token
      )

      tables.each_with_object({}) do |row, schema|
        table = row["table_name"]
        next unless table

        schema[table] = introspect_columns(table, token)
      end
    end

    private

    def issue_internal_token
      @jwt_issuer.issue_internal_token(
        role: "schema_scanner",
        datasource: @datasource,
        expires_at: 1.minute.from_now
      )
    end

    def introspect_columns(table, token)
      rows = @funl_client.introspect_columns(
        table: table,
        bearer: token
      )

      rows.map do |row|
        {
          name: row["column_name"],
          type: row["data_type"]
        }
      end
    end
  end
end
