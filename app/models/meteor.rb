require 'drb/drb'

class Meteor < ActiveRecord::Base
  class Shooter
    COUNTERS = [:count, :count_with]
    LISTINGS = [:listeners, :listeners_with, :channels, :signatures]
    ROUNDROBINS = [:signature]
    MAX_RETRY = 10
    DEFAULT_SHOOTER_URI = 'druby://localhost:7123'

    def initialize(config)
      config['shooting_star'] ||= {'shooter' => DEFAULT_SHOOTER_URI}
      uris = config['shooting_star']['shooter']
      @shooters = [uris].flatten.map{|uri| DRbObject.new_with_uri(uri)}
    end

    COUNTERS.each do |m|
      eval "def #{m}(*a, &b) call('#{m}',*a,&b).inject(0){|r,c| r+=c} end"
    end

    LISTINGS.each do |m|
      eval "def #{m}(*a, &b) call('#{m}',*a,&b).inject([]){|r,c|r.concat c} end"
    end
    
    ROUNDROBINS.each do |m|
      eval "def #{m}(*a, &b) round_robin('#{m}', *a, &b) end"
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

    def round_robin(method, *args, &block)
      @round_robin_counter = (@round_robin_counter.to_i + 1) % @shooters.size
      @shooters[@round_robin_counter].__send__(method, *args, &block)
    rescue Exception
      (@retry_counter = @retry_counter.to_i + 1) < MAX_RETRY ? retry : raise
    end
  end

  def self.shooter
    @@shooter ||= DRb.start_service && Shooter.new(configurations[RAILS_ENV])
  end

  def self.shoot(channel, javascript, tag = [])
    meteor = Meteor.new(:javascript => javascript)
    returning(meteor.save) do |succeeded|
      shooter.shoot(channel, meteor.id, tag) if succeeded
    end
  end
end
