class Api::AccessTokensController < Api::BaseController
  def create
    token = Current.organization.access_tokens.create!(
      name: params[:name],
      expires_at: params[:expires_at]
    )

    render json: { token: token.plaintext_token, id: token.id }, status: :created
  end

  def index
    render json: Current.organization.access_tokens.select(:id, :name, :active, :expires_at, :created_at)
  end

  def revoke
    token = Current.organization.access_tokens.find(params[:id])
    token.update!(active: false)
    head :no_content
  end
end
