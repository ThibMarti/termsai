require "test_helper"
require "ostruct"

class PunditSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "user@smoke.test", password: "password", first_name: "A", last_name: "B")
    @admin = User.create!(email: "admin@smoke.test", password: "password", first_name: "C", last_name: "D", admin: true)
    @offer = Offer.create!(name: "Starter", tokens_amount: 10, price_cents: 500)
  end

  def sign_in_as(user)
    post user_session_path, params: { user: { email: user.email, password: "password" } }
  end

  # Swaps a Stripe class method for a fixed return value for the duration of the block,
  # since tests must not make real network calls to Stripe.
  def stub_stripe(klass, method_name, return_value)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name) { |*| return_value }
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end

  def buy_offer(offer, session_id: "cs_test_#{offer.id}_#{Time.now.to_i}")
    checkout_session = OpenStruct.new(id: session_id, url: "https://checkout.stripe.test/#{session_id}")
    stub_stripe(Stripe::Checkout::Session, :create, checkout_session) do
      post orders_path, params: { order: { offer_id: offer.id } }
    end
    checkout_session
  end

  test "regular user can browse offers, buy one, and view their own data" do
    sign_in_as(@user)

    get offers_path
    assert_response :success

    checkout_session = nil
    assert_difference -> { Order.count } do
      checkout_session = buy_offer(@offer)
    end
    assert_redirected_to checkout_session.url
    order = Order.last
    assert_equal @user, order.user
    assert_equal @offer, order.offer
    assert_equal checkout_session.id, order.checkout_session_id

    get orders_path
    assert_response :success

    get token_path
    assert_response :success

    assert_difference -> { Scan.count } do
      post scans_path, params: { scan: { site_name: "Example", url: "https://example.com", content: "Some terms and conditions." } }
    end
    scan = Scan.last
    assert_redirected_to scan_path(scan)
    assert UserScan.exists?(user: @user, scan: scan)

    get scan_path(scan)
    assert_response :success
  end

  test "regular user can view their own order" do
    sign_in_as(@user)
    buy_offer(@offer)
    order = Order.last

    # needed since Stripe's success_url redirects the buyer here after checkout
    get order_path(order)
    assert_response :success
  end

  test "admin can view any order" do
    sign_in_as(@user)
    buy_offer(@offer)
    order = Order.last

    delete destroy_user_session_path
    sign_in_as(@admin)
    get order_path(order)
    assert_response :success
  end

  test "a second scan is blocked once the free token is used up" do
    sign_in_as(@user)
    post scans_path, params: { scan: { site_name: "Example", url: "https://example.com", content: "Some terms." } }
    assert_redirected_to scan_path(Scan.last)
    assert_not @user.reload.can_scan?

    post scans_path, params: { scan: { site_name: "Other", url: "https://other.example.com", content: "Other terms." } }
    assert_redirected_to dashboard_path
    assert_equal "No tokens left.", flash[:alert]
  end

  test "scanning an already-scanned url reuses the report and does not spend a token" do
    sign_in_as(@user)
    post scans_path, params: { scan: { site_name: "Example", url: "https://example.com", content: "Some terms." } }
    first_scan_id = Scan.last.id
    balance_after_first_scan = @user.reload.total_scan_allowance

    assert_no_difference -> { Scan.count } do
      post scans_path, params: { scan: { site_name: "Example", url: "https://example.com", content: "Different pasted text." } }
    end
    assert_redirected_to scan_path(first_scan_id)
    assert_equal 1, UserScan.where(scan_id: first_scan_id).count
    assert_equal balance_after_first_scan, @user.reload.total_scan_allowance
  end

  test "Stripe webhook grants tokens once a checkout session completes" do
    sign_in_as(@user)
    checkout_session = buy_offer(@offer)
    order = Order.last
    starting_balance = @user.total_scan_allowance

    event = OpenStruct.new(
      type: "checkout.session.completed",
      data: OpenStruct.new(object: OpenStruct.new(id: checkout_session.id))
    )
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"
    stub_stripe(Stripe::Webhook, :construct_event, event) do
      post webhooks_stripe_path, params: {}, headers: { "Stripe-Signature" => "test" }
    end
    assert_response :success

    assert_equal "paid", order.reload.state
    assert_equal starting_balance + @offer.tokens_amount, @user.reload.total_scan_allowance
  end
end
