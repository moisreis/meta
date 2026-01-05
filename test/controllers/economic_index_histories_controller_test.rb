require "test_helper"

class EconomicIndexHistoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @economic_index_history = economic_index_histories(:one)
  end

  test "should get index" do
    get economic_index_histories_url
    assert_response :success
  end

  test "should get new" do
    get new_economic_index_history_url
    assert_response :success
  end

  test "should create economic_index_history" do
    assert_difference("EconomicIndexHistory.count") do
      post economic_index_histories_url, params: { economic_index_history: {} }
    end

    assert_redirected_to economic_index_history_url(EconomicIndexHistory.last)
  end

  test "should show economic_index_history" do
    get economic_index_history_url(@economic_index_history)
    assert_response :success
  end

  test "should get edit" do
    get edit_economic_index_history_url(@economic_index_history)
    assert_response :success
  end

  test "should update economic_index_history" do
    patch economic_index_history_url(@economic_index_history), params: { economic_index_history: {} }
    assert_redirected_to economic_index_history_url(@economic_index_history)
  end

  test "should destroy economic_index_history" do
    assert_difference("EconomicIndexHistory.count", -1) do
      delete economic_index_history_url(@economic_index_history)
    end

    assert_redirected_to economic_index_histories_url
  end
end
