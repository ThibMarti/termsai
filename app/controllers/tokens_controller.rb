class TokensController < ApplicationController
  def show
    @hide_default_navbar = true
    @token = current_user.tokens.first || current_user.tokens.build
    authorize @token
    @total_tokens = current_user.tokens.sum(:token_amount)
  end
end
