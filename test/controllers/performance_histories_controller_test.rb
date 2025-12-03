require "test_helper"

class PerformanceHistoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @performance_history = performance_histories(:one)
  end

  test "should get index" do
    get performance_histories_url
    assert_response :success
  end

  test "should get new" do
    get new_performance_history_url
    assert_response :success
  end

  test "should create performance_history" do
    assert_difference("PerformanceHistory.count") do
      post performance_histories_url, params: { performance_history: {} }
    end

    assert_redirected_to performance_history_url(PerformanceHistory.last)
  end

  test "should show performance_history" do
    get performance_history_url(@performance_history)
    assert_response :success
  end

  test "should get edit" do
    get edit_performance_history_url(@performance_history)
    assert_response :success
  end

  test "should update performance_history" do
    patch performance_history_url(@performance_history), params: { performance_history: {} }
    assert_redirected_to performance_history_url(@performance_history)
  end

  test "should destroy performance_history" do
    assert_difference("PerformanceHistory.count", -1) do
      delete performance_history_url(@performance_history)
    end

    assert_redirected_to performance_histories_url
  end
end
