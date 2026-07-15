# config/initializers/stripe.rb
Stripe.api_key = ENV['STRIPE_SECRET_KEY']
