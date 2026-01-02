# frozen_string_literal: true

class Api::V1::GrantsController < Api::BaseController
  before_action :require_org!

  def fetch
    grant = find_grant!(params[:id])

    if grant.user != current_user
      return render json: { error: "Access denied" }, status: :forbidden
    end

    if grant.expires_at <= Time.current
      return render json: { error: "Grant expired" }, status: :forbidden
    end

    datasource =
      Datasources::ResolveForDataset.call!(
        org: current_org,
        dataset: grant.dataset
      )

    rows =
      Funl::Client.new(
        base_url: ENV["FUNL_URL"],
        datasource: datasource.connection_config
      ).execute(
        aql: grant.aql,
        bearer: grant.session_token
      )

    AUDIT_LOGGER.log(
      event: "grant.fetch.executed",
      actor: current_user,
      organization: current_org,
      details: {
        grant_ref: grant.ref,
        dataset: grant.dataset,
        fields: grant.fields,
        row_count: rows.size,
        aql: Aql::AuditSerializer.call(grant.aql)
      }
    )

    render json: {
      status: "ok",
      rows: rows
    }
  end

  private

  def find_grant!(identifier)
    Grant.where(organization: current_org).find_by(ref: identifier) ||
      Grant.where(organization: current_org).find_by(id: identifier) ||
      raise(ActiveRecord::RecordNotFound, "Grant not found")
  end
end
