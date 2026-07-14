class OrderController < ApplicationController
  def index
    @orders = policy_scope(Order)
  end

  def show
    @order = Order.find(params[:id])
    authorize @order
  end

  def create
    offer = Offer.find(order_params[:offer_id])
    @order = Order.new(user: current_user, offer: offer, amount_cents: offer.price_cents, state: "pending")
    authorize @order
    if @order.save
      redirect_to orders_path, notice: "Order created."
    else
      redirect_to offers_path, alert: @order.errors.full_messages.to_sentence
    end
  end

  private

  def order_params
    params.require(:order).permit(:offer_id)
  end
end
