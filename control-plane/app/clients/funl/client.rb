# frozen_string_literal: true

module Funl
  class Client
    DEFAULT_BASE_URL =
      ENV.fetch("FUNL_URL", "http://localhost:8080")

    def initialize(base_url: nil, datasource:)
      @base_url = (base_url || DEFAULT_BASE_URL).chomp("/")
      @datasource = datasource
    end

    def execute(aql:, bearer:, mask_fields: nil)
      payload = aql.deep_dup
      payload["mask_fields"] = mask_fields if mask_fields

      post(
        "/execute",
        body: { aql: payload, datasource: @datasource },
        bearer: bearer
      )
    end

    def introspect_tables(bearer:)
      post("/introspect", body: { datasource: @datasource, kind: "tables" }, bearer:)["rows"] || []
    end

    def introspect_columns(table:, bearer:)
      post(
        "/introspect",
        body: { datasource: @datasource, kind: "columns", table: table },
        bearer:
      )["rows"] || []
    end

    private

    def post(path, body:, bearer:)
      uri = URI("#{@base_url}#{path}")
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["Authorization"] = "Bearer #{bearer}" if bearer
      req.body = JSON.dump(body)

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(req)
      end

      handle_response(res)
    end

    def handle_response(res)
      case res.code.to_i
      when 200 then JSON.parse(res.body)
      when 401 then raise Funl::Unauthorized
      else
        raise Funl::Error, "Funl error #{res.code}: #{res.body}"
      end
    end
  end
end
