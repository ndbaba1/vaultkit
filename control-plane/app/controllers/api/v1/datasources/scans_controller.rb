# frozen_string_literal: true

class Api::V1::Datasources::ScansController < Api::BaseController
  before_action :require_org!
  before_action :require_admin!

  def create
    datasource = current_org.datasources.find_by!(name: params[:datasource_id])
    mode = params.fetch(:mode, "diff_only") # diff_only | apply

    scan_run = ScanRun.create!(
      organization: current_org,
      user: current_user,
      datasource_name: datasource.name,
      status: "queued"
    )

    # 1) Scan
    scanner = Datasources::DatasetScanner.new(
      funl_client: Funl::Client.new(
        base_url: ENV["FUNL_URL"],
        datasource: datasource.connection_config
      ),
      jwt_issuer: Rails.application.config.jwt_issuer
    )

    raw_schema = scanner.scan

    # 2) Classify
    classifier = Datasources::SchemaClassifier.new
    classified = classifier.classify(raw_schema)

    # 3) Normalize to registry dataset shape
    scanned_datasets = normalize_to_registry(classified, datasource.name)

    # 4) Reconcile against active registry
    reconciler = SchemaRegistry::Reconciler.new(
      org: current_org,
      actor: current_user
    )

    result = reconciler.reconcile!(
      datasource_name: datasource.name,
      scanned_datasets: scanned_datasets,
      mode: mode
    )

    scan_run.update!(
      status: "completed",
      raw_schema: raw_schema,
      classified_schema: classified,
      diff: result[:diff]
    )

    AUDIT_LOGGER.log(
      event: "datasource.scan.completed",
      actor: current_user,
      organization: current_org,
      details: {
        org: current_org.slug,
        datasource: datasource.name,
        mode: mode
      }
    )

    render json: {
      datasource: datasource.name,
      scan_id: scan_run.id,
      mode: mode,
      diff: result[:diff],
      applied: result[:applied]
    }
  rescue => e
    scan_run&.update!(status: "failed", error: e.message)

    AUDIT_LOGGER.log(
      event: "datasource.scan.failed",
      actor: current_user || nil,
      organization: current_org || nil,
      details: {
        org: current_org&.slug,
        datasource: params[:datasource_id],
        error: e.message
      }
    )

    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def normalize_to_registry(classified, datasource_name)
    classified.map do |entry|
      {
        "name" => entry[:table],
        "datasource" => datasource_name,
        "fields" => entry[:columns].map do |c|
          {
            "name" => c[:name],
            "type" => c[:type],
            "sensitivity" => c[:sensitivity],
            "tags" => [c[:category]].compact
          }
        end
      }
    end
  end

  def require_admin!
    unless current_user&.admin?
      render json: { error: "Forbidden" }, status: :forbidden
      return
    end
  end
end
