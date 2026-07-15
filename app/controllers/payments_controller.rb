class PaymentsController < ApplicationController
  # 🟢 ADD THIS LINE: This tells Pundit to skip authorization checks for these payment actions
  skip_after_action :verify_authorized, only: [:create_checkout_session, :success, :cancel]

  # This action creates the Stripe session and redirects the user
  def create_checkout_session
    # Get the quantity from the form, default to 1 if not provided
    token_quantity = params[:quantity].to_i
    token_quantity = 1 if token_quantity <= 0

    session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'eur',
          unit_amount: 50, # 50 cents = €0.50
          product_data: {
            name: 'Platform Token',
            description: 'Utility tokens for platform features',
          },
        },
        quantity: token_quantity,
      }],
      mode: 'payment',
      # Replace these URLs with your actual success and cancel routes
      success_url: root_url + "payments/success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: root_url + "payments/cancel",
      metadata: {
        # If you have a logged-in user system (like Devise), pass their ID
        user_id: current_user&.id,
        tokens_purchased: token_quantity
      }
    })

    redirect_to session.url, allow_other_host: true
  end

  # This action handles successful redirection
  def success
    @session = Stripe::Checkout::Session.retrieve(params[:session_id])
    # Here you can process the custom metadata you sent to Stripe
    @tokens = @session.metadata.tokens_purchased

    # Optional: Find your user and update their tokens here (or do this via Webhooks)
    # user = User.find(@session.metadata.user_id)
    # user.increment!(:token_count, @tokens.to_i)
  end

  # This action handles canceled payments
  def cancel
    flash[:alert] = "Payment was canceled."
    redirect_to root_path
  end
end
