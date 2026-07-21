require "test_helper"

class Api::V1::MeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "ext-me@example.com", password: "password", first_name: "Ext", last_name: "User")
  end

  def auth_headers(token)
    { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }
  end

  test "missing token is rejected with 401" do
    get api_v1_me_path, headers: { "Accept" => "application/json" }
    assert_response :unauthorized
  end

  test "invalid token is rejected with 401" do
    get api_v1_me_path, headers: auth_headers("not-a-real-token")
    assert_response :unauthorized
  end

  test "valid token with tokens available returns can_scan: true" do
    get api_v1_me_path, headers: auth_headers(@user.extension_token)
    assert_response :success
    assert_equal true, JSON.parse(response.body)["can_scan"]
  end

  test "valid token with no scan allowance returns can_scan: false" do
    @user.tokens.destroy_all
    get api_v1_me_path, headers: auth_headers(@user.extension_token)
    assert_equal false, JSON.parse(response.body)["can_scan"]
  end
end
