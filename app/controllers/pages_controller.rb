class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  def dashboard
    @scans = current_user.scans.order(created_at: :desc)
    @tokens_count = current_user.tokens.sum(:token_amount)
    @credits_amount = current_user.credit&.credits_amount.to_i
  end
end
