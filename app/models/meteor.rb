require 'drb/drb'

class Meteor < ActiveRecord::Base
  DEFAULT_SERVER_URI = 'localhost:8080'
  DEFAULT_SHOOTER_URI = 'druby://localhost:7123'

  class Shooter
    COUNTERS = [:count, :count_with]
    LISTINGS = [:listeners, :listeners_with, :channels, :signatures]
    EITHEROFS = [:signature]
    MAX_RETRY = 10

    def initialize(config)
      config['shooting_star'] ||= {'shooter' => Meteor::DEFAULT_SHOOTER_URI}
      uris = config['shooting_star']['shooter']
      @shooters = [uris].flatten.map{|uri| DRbObject.new(nil, uri)}
    end

    COUNTERS.each do |m|
      eval "def #{m}(*a, &b) call('#{m}',*a,&b).inject(0){|r,c| r+=c} end"
    end

    LISTINGS.each do |m|
      eval "def #{m}(*a, &b) call('#{m}',*a,&b).inject([]){|r,c|r.concat c} end"
    end
    
    EITHEROFS.each do |m|
      eval "def #{m}(*a, &b) round_robin('#{m}',*a,&b) end"
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
          Meteor::logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
        end
        result
      end || []
    end

    def round_robin(method, *args, &block)
      @round_robin_counter = (@round_robin_counter.to_i + 1) % @shooters.size
      @shooters[@round_robin_counter].__send__(method, *args, &block)
    rescue Exception
      (@retry_counter = @retry_counter.to_i + 1) <= MAX_RETRY ? retry : raise
    end
  end

  def self.config
    returning(configurations[RAILS_ENV]['shooting_star'] || {}) do |config|
      config['server'] ||= DEFAULT_SERVER_URI
      config['shooter'] ||= DEFAULT_SHOOTER_URI
    end
  end

  def self.servers
    config['server'].kind_of?(Array) ? config['server'] : [config['server']]
  end

  def self.server
    @round_robin_counter = (@round_robin_counter.to_i + 1) % servers.size
    servers[@round_robin_counter]
  end

  def self.shooter
    @@shooter ||= DRb.start_service && Shooter.new(configurations[RAILS_ENV])
  end

  def self.shoot(channel_path, javascript, tag = [], options = {})
    meteor = Meteor.new(:javascript => javascript)
    returning(meteor.save) do |succeeded|
      shooter.shoot(channel_path, meteor.id, tag, options) if succeeded
    end
  end
end
