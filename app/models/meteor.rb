require 'drb/drb'

class Meteor < ActiveRecord::Base
  class Shooter
    COUNTERS = [:count, :count_with]
    LISTINGS = [:listeners, :listeners_with, :channels, :signatures]

    def initialize(config)
      uris = config['shooting_star']['shooter']
      @shooters = [uris].flatten.map{|uri| DRbObject.new_with_uri(uri)}
    end

    COUNTERS.each do |m|
      define_method(m){|*a| call(m, *a).inject(0){|r,c| r += c}}
    end

    LISTINGS.each do |m|
      define_method(m){|*a| call(m, *a).inject([]){|r,c| r.concat c}}
    end

    def method_missing(method, *args, &block)
      call(method, *args, &block).first
    end

  private
    def call(method, *args, &block)
      @shooters.inject([]) do |result, shooter|
        begin
          result << shooter.__send__(method, *args, &block)
        rescue Exception => e
          Meteor.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
        end
        result
      end || []
    end
  end

  def self.shooter
    @@shooter ||= ::Meteor::Shooter.new(configurations[RAILS_ENV])
  end

  def self.shoot(channel, javascript, tag = [])
    meteor = Meteor.new(:javascript => javascript)
    returning(meteor.save) do |succeeded|
      shooter.shoot(channel, meteor.id, tag) if succeeded
    end
  end
end
