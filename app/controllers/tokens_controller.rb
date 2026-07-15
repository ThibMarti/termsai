class TokensController < ApplicationController
  def show
    @token = current_user.tokens.first || current_user.tokens.build
    authorize @token
    @total_tokens = current_user.tokens.sum(:token_amount)
  end
end
