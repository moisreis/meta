require "test_helper"

class FundValuationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fund_valuation = fund_valuations(:one)
  end

  test "should get index" do
    get fund_valuations_url
    assert_response :success
  end

  test "should get new" do
    get new_fund_valuation_url
    assert_response :success
  end

  test "should create fund_valuation" do
    assert_difference("FundValuation.count") do
      post fund_valuations_url, params: { fund_valuation: {} }
    end

    assert_redirected_to fund_valuation_url(FundValuation.last)
  end

  test "should show fund_valuation" do
    get fund_valuation_url(@fund_valuation)
    assert_response :success
  end

  test "should get edit" do
    get edit_fund_valuation_url(@fund_valuation)
    assert_response :success
  end

  test "should update fund_valuation" do
    patch fund_valuation_url(@fund_valuation), params: { fund_valuation: {} }
    assert_redirected_to fund_valuation_url(@fund_valuation)
  end

  test "should destroy fund_valuation" do
    assert_difference("FundValuation.count", -1) do
      delete fund_valuation_url(@fund_valuation)
    end

    assert_redirected_to fund_valuations_url
  end
end
