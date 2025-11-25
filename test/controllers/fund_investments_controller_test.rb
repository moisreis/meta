require "test_helper"

class FundInvestmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fund_investment = fund_investments(:one)
  end

  test "should get index" do
    get fund_investments_url
    assert_response :success
  end

  test "should get new" do
    get new_fund_investment_url
    assert_response :success
  end

  test "should create fund_investment" do
    assert_difference("FundInvestment.count") do
      post fund_investments_url, params: { fund_investment: {} }
    end

    assert_redirected_to fund_investment_url(FundInvestment.last)
  end

  test "should show fund_investment" do
    get fund_investment_url(@fund_investment)
    assert_response :success
  end

  test "should get edit" do
    get edit_fund_investment_url(@fund_investment)
    assert_response :success
  end

  test "should update fund_investment" do
    patch fund_investment_url(@fund_investment), params: { fund_investment: {} }
    assert_redirected_to fund_investment_url(@fund_investment)
  end

  test "should destroy fund_investment" do
    assert_difference("FundInvestment.count", -1) do
      delete fund_investment_url(@fund_investment)
    end

    assert_redirected_to fund_investments_url
  end
end
