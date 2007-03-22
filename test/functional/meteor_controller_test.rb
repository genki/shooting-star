require File.dirname(__FILE__) + '/../test_helper'
require 'meteor_controller'

# Re-raise errors caught by the controller.
class MeteorController; def rescue_action(e) raise e end; end

class MeteorControllerTest < Test::Unit::TestCase
  def setup
    @controller = MeteorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_truth
    assert true
  end
end
