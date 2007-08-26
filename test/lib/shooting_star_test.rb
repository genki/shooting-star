require File.join(File.dirname(__FILE__), '../test_helper')
require 'shooting_star'
require 'socket'
require 'thread'

$command_line = 'echo "testing"'

class ShootingStarTest < Test::Unit::TestCase
  class TestObserver
    include DRb::DRbUndumped
    def name; 'test-observer' end
    def enter(params) @params = params end
    def params; @params end
  end

  def setup
    @config = ShootingStar.configure :silent => true,
      :pid_file => 'tmp/pids/shooting_star.test.pid',
      :log_file => 'log/shooting_star.test.log',
      :server => {:host => '127.0.0.1', :port => 8081},
      :shooter => {:uri => 'druby://127.0.0.1:7124'}
    flag = false
    @thread = Thread.new{ShootingStar.start{flag = true}}
    Thread.pass until flag
    @query = "sig=0123456789&execute=http://127.0.0.1:4001/meteor/strike"
    @query2 = "sig=1123456789&execute=http://127.0.0.1:4001/meteor/strike"
  end

  def teardown
    ShootingStar.stop
    File.rm_f(@config.pid_file)
    File.rm_f @config.log_file
    @thread.join
  end

  def test_connection_with_invalid_method
    client = TCPSocket.open('127.0.0.1', 8081)
    assert_not_nil client
    send(client, "GET", "test/channel", @query)
    assert client.read.empty?
  end

  def test_connection
    client = TCPSocket.open('127.0.0.1', 8081)
    send(client, "POST", "test/channel", @query)
    assert_not_nil result = client.read
    assert_not_nil result.index('xhr.getResponseHeader')
    assert_not_nil result.index('test\/channel')
    client.close

    flag = false
    Thread.new do
      client = TCPSocket.open('127.0.0.1', 8081)
      send(client, "POST", "test/channel", "#{@query}&__t__=c")
      flag = true
    end
    Thread.pass until flag
    shooter = DRbObject.new_with_uri('druby://127.0.0.1:7124')
    assert_not_nil shooter
    shooter.shoot("test/channel", 12, [])
    assert_not_nil result = client.read
    assert_not_nil result.index('meteorStrike.execute(12,')
  end

  def test_multi_user_communication
    client1 = TCPSocket.open('127.0.0.1', 8081)
    client2 = TCPSocket.open('127.0.0.1', 8081)
    assert_not_nil client1
    assert_not_nil client2
    shooter = DRbObject.new_with_uri('druby://127.0.0.1:7124')
    assert_not_nil shooter
    observer = TestObserver.new
    assert_not_nil observer
    shooter.observe('test/channel', observer)
    flag = false
    assert_nil observer.params
    Thread.new do
      send(client1, "POST", "test/channel", "#{@query}&__t__=c")
      flag = true
    end
    Thread.pass until flag
    assert_not_nil observer.params
    assert_equal :enter, observer.params[:event]
    flag = false
    Thread.new do
      send(client2, "POST", "test/channel", "#{@query2}&__t__=c")
      flag = true
    end
    Thread.pass until flag
    assert_not_nil observer.params
    assert_equal :enter, observer.params[:event]
    shooter.shoot("test/channel", 12, [])
    assert_not_nil result1 = client1.read
    assert_not_nil result1.index('meteorStrike.execute(12,')
    assert_not_nil result2 = client2.read
    assert_not_nil result2.index('meteorStrike.execute(12,')
  end

  def test_xmlsocket_server
    client = TCPSocket.open('127.0.0.1', 8081)
    client.write("<policy-file-request/>\0")
    assert_not_nil client.read.index('allow-access-from')
  end

  def test_shooter_exists
    shooter = ShootingStar.shooter
    assert_not_nil shooter
  end

  def test_c10k_problem
    bin = File.join(RAILS_ROOT, 'bin/test_c10k_problem')
    src = File.join(File.dirname(__FILE__), 'test_c10k_problem.c')
    if !File.exist?(bin) || File.mtime(src) > File.mtime(bin)
      system "gcc #{src} -o #{bin}"
    end
    system bin 
  end

private
  def send(client, method, path, body)
    client.write "#{method} /#{path} HTTP/1.1\n\r" +
      "Host: #{@config.server.host}:#{@config.server.port}\n\r" +
      "Keep-Alive: 300\n\r" +
      "Content-length: #{body.length}\n\r" +
      "Connection: keep-alive\n\r\n\r#{body}"
  end
end
