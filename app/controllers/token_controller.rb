class TokenController < ApplicationController
  def show
    @token = current_user.token || current_user.build_token
    authorize @token
  end
end
