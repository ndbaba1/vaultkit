# frozen_string_literal: true

class Api::Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    token = request.env["warden-jwt_auth.token"]

    render json: {
      user: serialize_user(resource),
      token: token
    }, status: :ok
  end

  def respond_to_on_destroy
    head :no_content
  end

  def serialize_user(user)
    {
      id: user.id,
      email: user.email,
      role: user.role,
      organization_id: user.organization_id,
      organization_slug: user.organization&.slug
    }
  end
end
