require File.join(File.dirname(__FILE__), '../test_helper')
require 'shooting_star'
require 'socket'
require 'thread'

$command_line = 'echo "testing"'

class ShootingStarTest < Test::Unit::TestCase
  module TestObserver
    def self.enter(params) @params = params end
    def self.params; @params end
  end

  def setup
    @config = ShootingStar.configure :silent => true,
      :pid_file => 'log/shooting_star.test.pid',
      :log_file => 'log/shooting_star.test.log',
      :server => {:host => '127.0.0.1', :port => 8081},
      :shooter => {:uri => 'druby://127.0.0.1:7124'}
    mutex = Mutex.new
    mutex.lock
    @thread = Thread.new{ShootingStar.start{mutex.unlock}}
    mutex.lock
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

    mutex = Mutex.new
    mutex.lock
    Thread.new do
      client = TCPSocket.open('127.0.0.1', 8081)
      send(client, "POST", "test/channel", "#{@query}&__t__=c")
      mutex.unlock
    end
    mutex.lock
    shooter = DRbObject.new_with_uri('druby://127.0.0.1:7124')
    assert_not_nil shooter
    shooter.shoot("test/channel", 12, [])
    assert_not_nil result = client.read
    assert_not_nil result.index('meteor/strike/12')
  end

  def test_multi_user_communication
    client1 = TCPSocket.open('127.0.0.1', 8081)
    client2 = TCPSocket.open('127.0.0.1', 8081)
    assert_not_nil client1
    assert_not_nil client2
    shooter = DRbObject.new_with_uri('druby://127.0.0.1:7124')
    assert_not_nil shooter
    shooter.observe('test/channel', TestObserver)
    mutex = Mutex.new
    mutex.lock
    assert_nil TestObserver.params
    Thread.new do
      send(client1, "POST", "test/channel", "#{@query}&__t__=c")
      mutex.unlock
    end
    mutex.lock
    assert_nil TestObserver.params
    Thread.new do
      send(client2, "POST", "test/channel", "#{@query2}&__t__=c")
      mutex.unlock
    end
    mutex.lock
    assert_equal :enter, TestObserver.params[:event]
    assert_not_nil result1 = client1.read
    assert_not_nil result1.index('meteor/strike/event-')
    shooter.shoot("test/channel", 12, [])
    assert_not_nil result2 = client2.read
    assert_not_nil result2.index('meteor/strike/12')
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
