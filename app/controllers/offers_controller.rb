class OffersController < ApplicationController
  def index
    @hide_default_navbar = true
    @offers = policy_scope(Offer).order(:credits_amount)
    @best_value_offer = @offers.max_by(&:credits_amount)
  end
end
