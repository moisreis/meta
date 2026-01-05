require "test_helper"

class EconomicIndicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @economic_index = economic_indices(:one)
  end

  test "should get index" do
    get economic_indices_url
    assert_response :success
  end

  test "should get new" do
    get new_economic_index_url
    assert_response :success
  end

  test "should create economic_index" do
    assert_difference("EconomicIndex.count") do
      post economic_indices_url, params: { economic_index: {} }
    end

    assert_redirected_to economic_index_url(EconomicIndex.last)
  end

  test "should show economic_index" do
    get economic_index_url(@economic_index)
    assert_response :success
  end

  test "should get edit" do
    get edit_economic_index_url(@economic_index)
    assert_response :success
  end

  test "should update economic_index" do
    patch economic_index_url(@economic_index), params: { economic_index: {} }
    assert_redirected_to economic_index_url(@economic_index)
  end

  test "should destroy economic_index" do
    assert_difference("EconomicIndex.count", -1) do
      delete economic_index_url(@economic_index)
    end

    assert_redirected_to economic_indices_url
  end
end
