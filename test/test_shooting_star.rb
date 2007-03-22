$: << File.join(File.dirname(__FILE__), '../lib')
require 'test/unit'
require 'shooting_star'
require 'socket'
require 'thread'
require 'redgreen' rescue nil

COMMAND_LINE = 'echo "testing"'

class ShootingStarTest < Test::Unit::TestCase
  def setup
    @config = ShootingStar.configure(
      :silent => true,
      :server => {:host => '127.0.0.1', :port => 8080},
      :shooter => {:uri => 'druby://127.0.0.1:7123'})
    @thread = Thread.new do
      ShootingStar.start
    end
    Thread.pass while !File.exist?(@config.pid_file)
    @client = TCPSocket.open('127.0.0.1', 8080)
    @shooter = ShootingStar.shooter
  end

  def teardown
    ShootingStar.stop
    @thread.join
    File.rm_f(@config.pid_file)
  end

  def test_activation
    assert_not_nil @thread
  end

  def test_shooter
    assert_not_nil @shooter
  end

  def test_client
    assert_not_nil @client
  end

  def test_disconnection
    @client.close
  end

  def test_communication
    mutex = Mutex.new
    mutex.lock
    thread = Thread.new do
      #send 'GET', 'test_application/test_channel_name'
      mutex.unlock
    end
    mutex.lock
    thread.join
  end

private
  def send(method, path)
    @client.write "#{method} #{path} HTTP/1.1\n" +
      "Host: #{ShootingStar.host}:#{ShootingStar.port}\n" +
      "Keep-Alive: 300\n" +
      "Connection: keep-alive\n\n"
  end
end
