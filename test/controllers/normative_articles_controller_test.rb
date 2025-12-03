require "test_helper"

class NormativeArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @normative_article = normative_articles(:one)
  end

  test "should get index" do
    get normative_articles_url
    assert_response :success
  end

  test "should get new" do
    get new_normative_article_url
    assert_response :success
  end

  test "should create normative_article" do
    assert_difference("NormativeArticle.count") do
      post normative_articles_url, params: { normative_article: {} }
    end

    assert_redirected_to normative_article_url(NormativeArticle.last)
  end

  test "should show normative_article" do
    get normative_article_url(@normative_article)
    assert_response :success
  end

  test "should get edit" do
    get edit_normative_article_url(@normative_article)
    assert_response :success
  end

  test "should update normative_article" do
    patch normative_article_url(@normative_article), params: { normative_article: {} }
    assert_redirected_to normative_article_url(@normative_article)
  end

  test "should destroy normative_article" do
    assert_difference("NormativeArticle.count", -1) do
      delete normative_article_url(@normative_article)
    end

    assert_redirected_to normative_articles_url
  end
end
