require 'test/unit'
require 'rubygems'
require 'active_support'
require File.join(File.dirname(__FILE__), '../lib/meteor_strike')
begin
  require 'redgreen'
rescue
end

class MeteorStrikeTest < Test::Unit::TestCase
  def test_meteor_strike
    assert respond_to?(:meteor_strike)
    form_tag
    assert @form_tag
  end

private
  def form_tag(*arg, &block)
    @form_tag = true
  end

  include MeteorStrike::Helper
end
