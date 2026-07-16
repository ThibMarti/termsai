require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "tokens@test.com", password: "password", first_name: "A", last_name: "B")
    # signup already granted 1 free token; start from a clean slate for these assertions
    @user.tokens.destroy_all
  end

  test "a multi-token grant is decremented one at a time, not destroyed until it hits zero" do
    bundle = @user.tokens.create!(token_amount: 3)

    assert @user.can_scan?
    @user.consume_scan_allowance!
    assert_equal 2, bundle.reload.token_amount
    assert @user.can_scan?

    @user.consume_scan_allowance!
    assert_equal 1, bundle.reload.token_amount

    @user.consume_scan_allowance!
    assert_not Token.exists?(bundle.id)
    assert_not @user.can_scan?
  end
end
