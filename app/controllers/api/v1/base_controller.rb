class Api::V1::BaseController < ApplicationController
  # The Chrome extension has no Devise session to reuse — it authenticates
  # with a per-user bearer token instead (see User#extension_token), so
  # session-based auth and CSRF (which only guards session-cookie requests)
  # don't apply here.
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, raise: false

  before_action :require_extension_token!

  rescue_from RubyLLM::Error do
    render json: { error: "The analysis failed — please try again. Nothing was charged." }, status: :bad_gateway
  end

  private

  def require_extension_token!
    render json: { error: "Missing or invalid extension token." }, status: :unauthorized unless current_user
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = bearer_token.present? ? User.find_by(extension_token: bearer_token) : nil
  end

  def bearer_token
    request.headers["Authorization"].to_s.delete_prefix("Bearer ").presence
  end
end
