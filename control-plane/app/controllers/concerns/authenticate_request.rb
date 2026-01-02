module AuthenticateRequest
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    if jwt_present?
      authenticate_user! # Devise helper, sets current_user
      if current_user&.organization
        Current.organization = current_user.organization
      else
        render json: { error: "User organization not found" }, status: :forbidden
      end
      return
    end

    if api_key_present?
      token = AccessToken.verify(api_key_header)
      if token
        Current.organization = token.organization
      else
        render json: { error: "Invalid API Key" }, status: :unauthorized
      end
      return
    end

    render json: { error: "Missing credentials" }, status: :unauthorized
  end

  # Helpers
  def jwt_present?
    request.headers["Authorization"]&.start_with?("Bearer ")
  end

  def api_key_present?
    request.headers["X-API-Key"].present?
  end

  def api_key_header
    request.headers["X-API-Key"]
  end
end
