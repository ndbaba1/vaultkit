class Api::BaseController < ActionController::API
  include AuthenticateRequest
end
