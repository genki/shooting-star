require 'test/unit'
require File.join(File.dirname(__FILE__), '../lib/meteor_strike')
begin
  require 'rubygems'
  require 'redgreen'
rescue
end

class MeteorStrikeTest < Test::Unit::TestCase
  include MeteorStrike::Helper

  def test_meteor_strike
    assert respond_to?(:meteor_strike)
  end
end
