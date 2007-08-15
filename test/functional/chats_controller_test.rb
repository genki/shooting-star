require File.dirname(__FILE__) + '/../test_helper'
require 'chats_controller'
require 'shooting_star'

# Re-raise errors caught by the controller.
class ChatsController; def rescue_action(e) raise e end; end

class ChatsControllerTest < Test::Unit::TestCase
  fixtures :chats

  def setup
    @controller = ChatsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @config = ShootingStar.configure :silent => true,
      :pid_file => 'tmp/pids/shooting_star.test.pid',
      :log_file => 'log/shooting_star.test.log',
      :server => {:host => '127.0.0.1', :port => 8081},
      :shooter => {:uri => 'druby://127.0.0.1:7124'}
    flag = false
    @thread = Thread.new{ShootingStar.start{flag = true}}
    Thread.pass until flag
  end

  def teardown
    ShootingStar.stop
    File.rm_f @config.pid_file
    File.rm_f @config.log_file
    @thread.join
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:chats)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_chat
    old_count = Chat.count
    post :create, :chat_name => 'bob',
      :chat_message => 'hello', :chat_tag => 'foo bar'
    assert_equal old_count+1, Chat.count
    assert_response :success
  end

  def test_should_show_chat
    get :show, :id => 1
    assert_response :success
  end
end
