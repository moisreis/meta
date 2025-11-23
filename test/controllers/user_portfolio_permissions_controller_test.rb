require "test_helper"

class UserPortfolioPermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_portfolio_permission = user_portfolio_permissions(:one)
  end

  test "should get index" do
    get user_portfolio_permissions_url
    assert_response :success
  end

  test "should get new" do
    get new_user_portfolio_permission_url
    assert_response :success
  end

  test "should create user_portfolio_permission" do
    assert_difference("UserPortfolioPermission.count") do
      post user_portfolio_permissions_url, params: { user_portfolio_permission: {} }
    end

    assert_redirected_to user_portfolio_permission_url(UserPortfolioPermission.last)
  end

  test "should show user_portfolio_permission" do
    get user_portfolio_permission_url(@user_portfolio_permission)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_portfolio_permission_url(@user_portfolio_permission)
    assert_response :success
  end

  test "should update user_portfolio_permission" do
    patch user_portfolio_permission_url(@user_portfolio_permission), params: { user_portfolio_permission: {} }
    assert_redirected_to user_portfolio_permission_url(@user_portfolio_permission)
  end

  test "should destroy user_portfolio_permission" do
    assert_difference("UserPortfolioPermission.count", -1) do
      delete user_portfolio_permission_url(@user_portfolio_permission)
    end

    assert_redirected_to user_portfolio_permissions_url
  end
end
