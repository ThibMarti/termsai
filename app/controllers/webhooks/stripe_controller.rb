module Webhooks
  class StripeController < ActionController::Base
    FULFILLABLE_EVENTS = %w[checkout.session.completed checkout.session.async_payment_succeeded].freeze

    skip_before_action :verify_authenticity_token, raise: false

    def create
      event = verify_event!
      fulfill_order(event.data.object) if FULFILLABLE_EVENTS.include?(event.type)
      head :ok
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      head :bad_request
    end

    private

    def verify_event!
      Stripe::Webhook.construct_event(
        request.body.read,
        request.headers["Stripe-Signature"],
        ENV.fetch("STRIPE_WEBHOOK_SECRET")
      )
    end

    def fulfill_order(session)
      order = Order.find_by(checkout_session_id: session.id)
      return if order.nil? || order.state == "paid"

      order.update!(state: "paid")
      order.user.tokens.create!(token_amount: order.offer.tokens_amount)
    end
  end
end
