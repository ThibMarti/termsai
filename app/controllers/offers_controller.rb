class OffersController < ApplicationController
  def index
    @hide_default_navbar = true
    @offers = policy_scope(Offer).order(:tokens_amount)
    @best_value_offer = @offers.max_by(&:tokens_amount)
  end
end
