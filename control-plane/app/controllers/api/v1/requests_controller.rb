# frozen_string_literal: true

class Api::V1::RequestsController < Api::BaseController
  before_action :require_org!

  def index
    results =
      Requests::List.call(
        org: current_org,
        user: current_user,
        state: params[:state] || "all"
      )

    AUDIT_LOGGER.log(
      event: "request.listed",
      actor: current_user,
      organization: current_org,
      details: { state: params[:state], count: results.size }
    )

    render json: results
  end

  def create
    aql = params.require(:aql).to_unsafe_h

    options =
      params.fetch(:options, {}).permit(
        :environment,
        :requester_region,
        :dataset_region,
        :requester_clearance
      ).to_h.symbolize_keys

    bundle = current_org.active_policy_bundle
    registry = bundle.fetch("registry")
    raise "No active policy bundle for organization" unless bundle

    dataset =
      aql["dataset"] ||
      aql["source_table"] ||
      raise(ArgumentError, "AQL must include dataset or source_table")

    datasource = Datasources::ResolveForDataset.call!(
      org: current_org,
      dataset: dataset,
    )

    orchestrator = Orchestration::RequestOrchestrator.new(
      policy_engine: PolicyExecution::PolicyEngine.new(
        policies: bundle.fetch("policies"),
        registry: registry,
      ),
      registry: registry,
      grant_finder: Grants::Finder.new,
      grant_issuer: Grants::Issuer.new,
      approval_service: PolicyApprovals::Service.new,
      funl_client: Funl::Client.new(
        base_url: ENV["FUNL_URL"],
        datasource: datasource.connection_config
      ),
      audit_logger: AUDIT_LOGGER
    )

    result = orchestrator.execute(
      aql: aql,
      actor: current_user,
      options: options
    )

    render json: normalize_result(result),
           status: http_status_for(result)

  rescue => e
    AUDIT_LOGGER.log(
      event: "request.failed",
      actor: current_user,
      organization: current_org,
      details: { error: e.message }
    )

    render json: { error: e.message },
           status: :unprocessable_content
  end

  private

  def http_status_for(result)
    case result[:status]
    when :denied   then :forbidden
    when :queued   then :accepted
    when :granted  then :ok
    when :ok       then :ok
    else :ok
    end
  end

  def normalize_result(result)
    result.deep_stringify_keys
  end
end
