class OrdersController < ApplicationController
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
      redirect_to_checkout(@order, offer)
    else
      redirect_to offers_path, alert: @order.errors.full_messages.to_sentence
    end
  end

  private

  def redirect_to_checkout(order, offer)
    session = Stripe::Checkout::Session.create(
      mode: "payment",
      customer_email: current_user.email,
      line_items: [line_item_for(offer)],
      success_url: order_url(order),
      cancel_url: offers_url,
      metadata: { order_id: order.id }
    )
    order.update!(checkout_session_id: session.id)
    redirect_to session.url, allow_other_host: true
  end

  def line_item_for(offer)
    {
      quantity: 1,
      price_data: { currency: "eur", unit_amount: offer.price_cents, product_data: { name: offer.name } }
    }
  end

  def order_params
    params.require(:order).permit(:offer_id)
  end
end
