module AuthenticateRequest
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    bearer = request.headers["Authorization"]&.split("Bearer ")&.last
    api_key = request.headers["X-API-Key"]

    if bearer.present?
      if current_user&.organization
        Current.organization = current_user.organization
      else
        render json: { error: "User organization not found" }, status: :forbidden
      end
      return
    end

    if api_key.present?
      token = AccessToken.verify(api_key)
      if token
        Current.organization = token.organization
      else
        render json: { error: "Invalid API Key" }, status: :unauthorized
      end
      return
    end

    render json: { error: "Missing credentials" }, status: :unauthorized
  end
end
