class CreditController < ApplicationController
  def show
    @credit = current_user.credit || current_user.build_credit
    authorize @credit
  end
end
