require File.join(File.dirname(__FILE__), '../test_helper')
require 'shooting_star'
require 'socket'
require 'thread'

$command_line = 'echo "testing"'

class ShootingStarTest < Test::Unit::TestCase
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
  end

  def teardown
    ShootingStar.stop
    File.rm_f(@config.pid_file)
    File.rm_f @config.log_file
    @thread.join
  end

  def test_connection
    client = TCPSocket.open('127.0.0.1', 8081)
    assert_not_nil client
    send client, "GET", "test/channel"
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
  def send(client, method, path)
    client.write "#{method} #{path} HTTP/1.1\n\r" +
      "Host: #{@config.server.host}:#{@config.server.port}\n\r" +
      "Keep-Alive: 300\n\r" +
      "Connection: keep-alive\n\r\n\r"
  end
end
