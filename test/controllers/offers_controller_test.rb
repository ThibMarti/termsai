require "test_helper"

class OffersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "buyer@offers.test", password: "password", first_name: "A", last_name: "B")
    Offer.create!(name: "Starter Pack", credits_amount: 10, price_cents: 500)
    Offer.create!(name: "Pro Pack", credits_amount: 50, price_cents: 2000)
    post user_session_path, params: { user: { email: @user.email, password: "password" } }
  end

  test "index renders both packs with a buy button each" do
    get offers_path
    assert_response :success
    assert_select "h1", text: "Buy tokens"
    assert_select "form[action^=?]", orders_path, count: 2
  end

  test "index marks the offer with the most credits as best value" do
    get offers_path
    assert_response :success
    assert_match(/Best value/, response.body)
  end
end
