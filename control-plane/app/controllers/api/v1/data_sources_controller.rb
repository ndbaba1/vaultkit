class Api::V1::DataSourcesController < Api::BaseController
  before_action :require_org!
  before_action :set_data_source, only: [:show, :update]

  def index
    render json: current_org.data_sources.select(:id, :name, :engine, :mode, :provider, :metadata, :created_at, :updated_at)
  end

  def show
    render json: serialize(@data_source)
  end

  def create
    ds = current_org.data_sources.new(base_params.merge(created_by: current_user.id))

    if params[:mode] == "secret_provider"
      ds.mode      = "secret_provider"
      ds.provider  = secret_params[:provider]
      ds.config    = {
        "secret_ref"  => secret_params[:secret_ref],
        "role_arn"    => secret_params[:role_arn],
        "external_id" => secret_params[:external_id],
        "project_id"  => secret_params[:project_id],  # gcp
        "vault_path"  => secret_params[:vault_path]   # hashicorp vault
      }.compact
    else
      ds.mode = "local_encrypted"
      ds.local_credentials = local_params.to_h
    end

    if ds.save
      render json: serialize(ds), status: :created
    else
      render json: { errors: ds.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    @data_source.metadata = @data_source.metadata.merge(params[:metadata].to_h) if params[:metadata]
    if @data_source.save
      render json: serialize(@data_source)
    else
      render json: { errors: @data_source.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_data_source
    @data_source = current_org.data_sources.find(params[:id])
  end

  def base_params
    params.permit(:name, :engine, :mode, metadata: {})
  end

  def secret_params
    params.permit(:provider, :secret_ref, :role_arn, :external_id, :project_id, :vault_path)
  end

  def local_params
    params.require(:credentials).permit(:host, :port, :database, :username, :password, :sslmode)
  end

  def serialize(ds)
    {
      id: ds.id,
      name: ds.name,
      engine: ds.engine,
      mode: ds.mode,
      provider: ds.provider,
      metadata: ds.metadata,
      # For security: DO NOT return encrypted payloads
    }
  end
end
