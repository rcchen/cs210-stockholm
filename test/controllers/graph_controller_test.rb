require 'test_helper'

class GraphControllerTest < ActionController::TestCase
  test "should get line" do
    get :line
    assert_response :success
  end

end
