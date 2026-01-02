# frozen_string_literal: true

class Api::V1::DatasourcesController < Api::BaseController
  before_action :require_org!
  before_action :require_admin!

  def index
    datasources = current_org.datasources.order(:name)
    render json: datasources.map { |ds| serialize(ds) }
  end

  def show
    ds = current_org.datasources.find_by!(name: params[:id])
    render json: serialize(ds)
  end

  def create
    ds = current_org.datasources.create!(
      name: params.require(:name),
      engine: params.require(:engine),
      username: params[:username],
      password: params[:password],
      config: params[:config] || {}
    )

    AUDIT_LOGGER.log(
      event: "datasource.created",
      actor: current_user,
      organization: current_org,
      details: {
        org: current_org.slug,
        actor_email: current_user&.email,
        name: ds.name,
        engine: ds.engine
      }
    )

    render json: serialize(ds), status: :created
  end

  private

  def require_admin!
    unless current_user&.admin?
      render json: { error: "Forbidden" }, status: :forbidden
      return
    end
  end

  def serialize(ds)
    {
      name: ds.name,
      engine: ds.engine,
      config: ds.config,
      created_at: ds.created_at,
      updated_at: ds.updated_at
    }
  end
end
