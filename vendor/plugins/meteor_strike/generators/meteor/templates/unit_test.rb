require File.dirname(__FILE__) + '/../test_helper'

class MeteorTest < Test::Unit::TestCase
  def test_creation
    initial_count = Meteor.count
    assert Meteor.create(:javascript => %Q{
      alert(1);
    })
    assert_equal initial_count + 1, Meteor.count
  end
end
