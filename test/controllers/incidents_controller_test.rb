require "test_helper"

class IncidentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get incidents_index_url
    assert_response :success
  end

  test "should get replay" do
    get incidents_replay_url
    assert_response :success
  end
end
