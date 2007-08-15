require File.join(File.dirname(__FILE__), '../test_helper')
require 'thread'
require 'ext/asteroid'
require 'socket'

module Server
  def receive_data(data)
    send_data data
    write_and_close
  end

  def post_init
    $post_init_test = true
  end

  def unbind
    $unbind_test = true
  end
end

class ShootingStarTest < Test::Unit::TestCase
  def setup
    flag = false
    @thread = Thread.new{Asteroid::run('127.0.0.1', 7124, Server){flag = true}}
    Thread.pass until flag
  end

  def teardown
    Asteroid::stop
    @thread.join
  end

  def test_communication
    c = TCPSocket.open('127.0.0.1', 7124)
    c.write "test"
    assert_equal "test", c.read
    assert $post_init_test
  end

  def test_unbind
    c = TCPSocket.open('127.0.0.1', 7124)
    c.close
    Thread.pass
    assert $unbind_test
  end

  def test_broad_cast
    c1 = TCPSocket.open('127.0.0.1', 7124)
    c2 = TCPSocket.open('127.0.0.1', 7124)
    c1.write "test1"
    c2.write "test2"
    assert_equal "test1", c1.read
    assert_equal "test2", c2.read
  end
end
