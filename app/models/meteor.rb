require 'drb/drb'

class Meteor < ActiveRecord::Base
  def self.shooter
    @@shooter ||= DRbObject.new_with_uri(
      configurations[RAILS_ENV]['shooting_star']['shooter'])
  end

  def self.shoot(channel, javascript, tag = [])
    meteor = Meteor.new(:javascript => javascript)
    returning(meteor.save) do |succeeded|
      shooter.shoot(channel, meteor.id, tag) if succeeded
    end
  end
end
