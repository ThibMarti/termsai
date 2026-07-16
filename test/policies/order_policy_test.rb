require "test_helper"

class OrderPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@policy.test", password: "password", first_name: "A", last_name: "B")
    @other = User.create!(email: "other@policy.test", password: "password", first_name: "C", last_name: "D")
    @admin = User.create!(email: "admin@policy.test", password: "password", first_name: "E", last_name: "F",
                          admin: true)
    offer = Offer.create!(name: "Starter", credits_amount: 10, price_cents: 500)
    @order = Order.create!(user: @owner, offer: offer, amount_cents: 500, state: "pending")
  end

  test "the owner can view their own order" do
    assert OrderPolicy.new(@owner, @order).show?
  end

  test "an admin can view any order" do
    assert OrderPolicy.new(@admin, @order).show?
  end

  test "a different non-admin user cannot view someone else's order" do
    assert_not OrderPolicy.new(@other, @order).show?
  end
end
