require "test_helper"

class RedemptionAllocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @redemption_allocation = redemption_allocations(:one)
  end

  test "should get index" do
    get redemption_allocations_url
    assert_response :success
  end

  test "should get new" do
    get new_redemption_allocation_url
    assert_response :success
  end

  test "should create redemption_allocation" do
    assert_difference("RedemptionAllocation.count") do
      post redemption_allocations_url, params: { redemption_allocation: {} }
    end

    assert_redirected_to redemption_allocation_url(RedemptionAllocation.last)
  end

  test "should show redemption_allocation" do
    get redemption_allocation_url(@redemption_allocation)
    assert_response :success
  end

  test "should get edit" do
    get edit_redemption_allocation_url(@redemption_allocation)
    assert_response :success
  end

  test "should update redemption_allocation" do
    patch redemption_allocation_url(@redemption_allocation), params: { redemption_allocation: {} }
    assert_redirected_to redemption_allocation_url(@redemption_allocation)
  end

  test "should destroy redemption_allocation" do
    assert_difference("RedemptionAllocation.count", -1) do
      delete redemption_allocation_url(@redemption_allocation)
    end

    assert_redirected_to redemption_allocations_url
  end
end
