require "test_helper"

class PunditSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "user@smoke.test", password: "password", first_name: "A", last_name: "B")
    @admin = User.create!(email: "admin@smoke.test", password: "password", first_name: "C", last_name: "D", admin: true)
    @offer = Offer.create!(name: "Starter", credits_amount: 10, price_cents: 500)
  end

  def sign_in_as(user)
    post user_session_path, params: { user: { email: user.email, password: "password" } }
  end

  test "regular user can browse offers, buy one, and view their own data" do
    sign_in_as(@user)

    get offers_path
    assert_response :success

    get offer_path(@offer)
    assert_response :success

    assert_difference -> { Order.count } do
      post orders_path, params: { order: { offer_id: @offer.id } }
    end
    assert_redirected_to orders_path
    order = Order.last
    assert_equal @user, order.user
    assert_equal @offer, order.offer

    get orders_path
    assert_response :success

    get credit_path
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

    # non-admin cannot view an order directly (OrderPolicy#show? is admin-only)
    assert_raises(Pundit::NotAuthorizedError) do
      get order_path(order)
    end
  end

  test "admin can view any order" do
    sign_in_as(@user)
    post orders_path, params: { order: { offer_id: @offer.id } }
    order = Order.last

    delete destroy_user_session_path
    sign_in_as(@admin)
    get order_path(order)
    assert_response :success
  end

  test "a second scan is blocked once the free token is used and there is no credit" do
    sign_in_as(@user)
    post scans_path, params: { scan: { site_name: "Example", url: "https://example.com", content: "Some terms." } }
    assert_redirected_to scan_path(Scan.last)
    assert_not @user.reload.can_scan?

    post scans_path, params: { scan: { site_name: "Other", url: "https://other.example.com", content: "Other terms." } }
    assert_redirected_to dashboard_path
    assert_equal "No tokens or credits left.", flash[:alert]
  end
end
