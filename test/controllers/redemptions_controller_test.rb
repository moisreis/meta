require "test_helper"

class RedemptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @redemption = redemptions(:one)
  end

  test "should get index" do
    get redemptions_url
    assert_response :success
  end

  test "should get new" do
    get new_redemption_url
    assert_response :success
  end

  test "should create redemption" do
    assert_difference("Redemption.count") do
      post redemptions_url, params: { redemption: {} }
    end

    assert_redirected_to redemption_url(Redemption.last)
  end

  test "should show redemption" do
    get redemption_url(@redemption)
    assert_response :success
  end

  test "should get edit" do
    get edit_redemption_url(@redemption)
    assert_response :success
  end

  test "should update redemption" do
    patch redemption_url(@redemption), params: { redemption: {} }
    assert_redirected_to redemption_url(@redemption)
  end

  test "should destroy redemption" do
    assert_difference("Redemption.count", -1) do
      delete redemption_url(@redemption)
    end

    assert_redirected_to redemptions_url
  end
end
