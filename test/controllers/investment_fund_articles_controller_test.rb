require "test_helper"

class InvestmentFundArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @investment_fund_article = investment_fund_articles(:one)
  end

  test "should get index" do
    get investment_fund_articles_url
    assert_response :success
  end

  test "should get new" do
    get new_investment_fund_article_url
    assert_response :success
  end

  test "should create investment_fund_article" do
    assert_difference("InvestmentFundArticle.count") do
      post investment_fund_articles_url, params: { investment_fund_article: {} }
    end

    assert_redirected_to investment_fund_article_url(InvestmentFundArticle.last)
  end

  test "should show investment_fund_article" do
    get investment_fund_article_url(@investment_fund_article)
    assert_response :success
  end

  test "should get edit" do
    get edit_investment_fund_article_url(@investment_fund_article)
    assert_response :success
  end

  test "should update investment_fund_article" do
    patch investment_fund_article_url(@investment_fund_article), params: { investment_fund_article: {} }
    assert_redirected_to investment_fund_article_url(@investment_fund_article)
  end

  test "should destroy investment_fund_article" do
    assert_difference("InvestmentFundArticle.count", -1) do
      delete investment_fund_article_url(@investment_fund_article)
    end

    assert_redirected_to investment_fund_articles_url
  end
end
