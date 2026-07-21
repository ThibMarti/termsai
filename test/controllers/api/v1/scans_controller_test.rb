require "test_helper"

class Api::V1::ScansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "ext-scans@example.com", password: "password", first_name: "Ext", last_name: "User")
  end

  def post_scan(attrs, token: nil)
    headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
    headers["Authorization"] = "Bearer #{token}" if token
    post api_v1_scans_path, params: { scan: attrs }.to_json, headers: headers
  end

  # Swaps ScanAnalyzer#call for a version that raises RubyLLM::Error, for the
  # duration of the block — same "swap a method, restore after" pattern as
  # PunditSmokeTest#stub_stripe.
  def stub_scan_analyzer_failure
    original = ScanAnalyzer.instance_method(:call)
    ScanAnalyzer.define_method(:call) { raise RubyLLM::Error, "boom" }
    yield
  ensure
    ScanAnalyzer.define_method(:call, original)
  end

  test "missing token is rejected with 401, no redirect" do
    post_scan({ site_name: "Example", url: "https://example.com", content: "Some terms." })
    assert_response :unauthorized
  end

  test "invalid token is rejected with 401" do
    post_scan({ site_name: "Example", url: "https://example.com", content: "Some terms." }, token: "bogus")
    assert_response :unauthorized
  end

  test "creates a scan, consumes a token, returns 201 with the risk report" do
    assert_difference -> { Scan.count } do
      post_scan(
        { site_name: "Example", url: "https://example.com", content: "Some terms and conditions." },
        token: @user.extension_token
      )
    end
    assert_response :created

    body = JSON.parse(response.body)
    assert body["risk_score"].present?
    assert body["full_report"].present?
    assert_not @user.reload.can_scan?
  end

  test "scanning an already-scanned url reuses the report, returns 200, and does not consume a token" do
    existing = Scan.create!(
      url: "https://example.com", site_name: "Example", content: "Some terms.",
      full_report: { "summary" => "x", "risk_score" => 7, "categories" => [], "gdpr_flags" => [], "ai_act_flags" => [] },
      risk_score: 7
    )

    assert_no_difference -> { Scan.count } do
      post_scan(
        { site_name: "Example", url: "https://example.com", content: "Different pasted text." },
        token: @user.extension_token
      )
    end
    assert_response :ok
    assert_equal existing.id, JSON.parse(response.body)["id"]
    assert @user.reload.can_scan?
  end

  test "a user with no tokens left gets 402 payment required" do
    @user.tokens.destroy_all
    post_scan(
      { site_name: "Example", url: "https://no-tokens.example.com", content: "Some terms." },
      token: @user.extension_token
    )
    assert_response :payment_required
  end

  test "RubyLLM::Error during analysis is rescued and returns 502, no token spent" do
    stub_scan_analyzer_failure do
      post_scan(
        { site_name: "Example", url: "https://fails.example.com", content: "Some terms." },
        token: @user.extension_token
      )
    end

    assert_response :bad_gateway
    assert_nil Scan.find_by(url: "https://fails.example.com")
    assert @user.reload.can_scan?
  end
end
