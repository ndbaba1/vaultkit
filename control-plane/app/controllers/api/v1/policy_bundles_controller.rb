#frozen_string_literal: true

class Api::V1::PolicyBundlesController < Api::BaseController
  before_action :set_org

  def create
    bundle = params.require(:bundle).to_unsafe_h

    PolicyBundles::Validator.validate!(bundle) # schema + checksum checks

    version = PolicyBundles::Store.store!(
      org: @org,
      actor: current_user,
      bundle: bundle,
      activate: ActiveModel::Type::Boolean.new.cast(params[:activate])
    )

    render json: {
      status: "ok",
      bundle_version: version.bundle_version,
      checksum: version.checksum,
      state: version.state
    }, status: :created
  end

  def activate
    version = @org.policy_bundle_versions.find_by!(bundle_version: params[:bundle_version])
    PolicyBundles::Activator.activate!(org: @org, version: version, actor: current_user)

    render json: { status: "ok", activated: version.bundle_version }
  end

  def rollback
    target = @org.policy_bundle_versions.find_by!(bundle_version: params.require(:to))
    PolicyBundles::Activator.activate!(org: @org, version: target, actor: current_user)

    render json: { status: "ok", rolled_back_to: target.bundle_version }
  end

  private

  def set_org
    @org = Current.organization
    raise ActiveRecord::RecordNotFound, "Organization not found" unless @org
  end
end
