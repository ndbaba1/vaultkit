# frozen_string_literal: true

class Api::BaseController < ActionController::API
  include AuthenticateRequest

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request

  # Only rescue unexpected errors in production
  rescue_from StandardError, with: :handle_internal_error if Rails.env.production?

  attr_reader :current_org

  protected

  def require_org!
    set_org!
  end

  def set_org!
    slug = params[:org_slug] ||
      params[:org_org_slug] ||
      params[:organization_slug]
    raise ActionController::ParameterMissing, :org_slug unless slug

    @current_org = Organization.find_by!(slug: slug)

    # Enforce tenant isolation
    if Current.organization && Current.organization.id != @current_org.id
      render json: { error: "Forbidden" }, status: :forbidden
      return
    end

    Current.organization ||= @current_org
  end

  private

  def handle_not_found(e)
    Rails.logger.info(e.message)
    render json: { error: "Not Found" }, status: :not_found
  end

  def handle_bad_request(e)
    render json: { error: e.message }, status: :bad_request
  end

  def handle_internal_error(e)
    Rails.logger.error(
      "[#{e.class}] #{e.message}\n#{e.backtrace.take(10).join("\n")}"
    )

    render json: { error: "Internal server error" }, status: :internal_server_error
  end
end
