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
      post scans_path, params: { scan: { url: "https://example.com" } }
    end
    scan = Scan.last
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

  test "posting the same url twice reuses the scan and does not duplicate the user_scan" do
    sign_in_as(@user)
    post scans_path, params: { scan: { url: "https://example.com" } }
    first_scan_id = Scan.last.id

    assert_no_difference -> { Scan.count } do
      post scans_path, params: { scan: { url: "https://example.com" } }
    end
    assert_equal first_scan_id, Scan.last.id
    assert_equal 1, UserScan.where(scan_id: first_scan_id).count
  end
end
