require "test_helper"

class CheckingAccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking_account = checking_accounts(:one)
  end

  test "should get index" do
    get checking_accounts_url
    assert_response :success
  end

  test "should get new" do
    get new_checking_account_url
    assert_response :success
  end

  test "should create checking_account" do
    assert_difference("CheckingAccount.count") do
      post checking_accounts_url, params: { checking_account: {} }
    end

    assert_redirected_to checking_account_url(CheckingAccount.last)
  end

  test "should show checking_account" do
    get checking_account_url(@checking_account)
    assert_response :success
  end

  test "should get edit" do
    get edit_checking_account_url(@checking_account)
    assert_response :success
  end

  test "should update checking_account" do
    patch checking_account_url(@checking_account), params: { checking_account: {} }
    assert_redirected_to checking_account_url(@checking_account)
  end

  test "should destroy checking_account" do
    assert_difference("CheckingAccount.count", -1) do
      delete checking_account_url(@checking_account)
    end

    assert_redirected_to checking_accounts_url
  end
end
