require "test_helper"

class InvestmentFundsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @investment_fund = investment_funds(:one)
  end

  test "should get index" do
    get investment_funds_url
    assert_response :success
  end

  test "should get new" do
    get new_investment_fund_url
    assert_response :success
  end

  test "should create investment_fund" do
    assert_difference("InvestmentFund.count") do
      post investment_funds_url, params: { investment_fund: {} }
    end

    assert_redirected_to investment_fund_url(InvestmentFund.last)
  end

  test "should show investment_fund" do
    get investment_fund_url(@investment_fund)
    assert_response :success
  end

  test "should get edit" do
    get edit_investment_fund_url(@investment_fund)
    assert_response :success
  end

  test "should update investment_fund" do
    patch investment_fund_url(@investment_fund), params: { investment_fund: {} }
    assert_redirected_to investment_fund_url(@investment_fund)
  end

  test "should destroy investment_fund" do
    assert_difference("InvestmentFund.count", -1) do
      delete investment_fund_url(@investment_fund)
    end

    assert_redirected_to investment_funds_url
  end
end
