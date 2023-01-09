require 'test_helper'

class ExampleControllerTest < ActionDispatch::IntegrationTest
  test 'should get redirect' do
    get example_redirect_url
    assert_response :success
  end
end
