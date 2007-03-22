require 'set'

module ShootingStar
  class Channel
    class InvalidIdError < StandardError; end
    attr_reader :path, :waiters
    @@channels = {}

    def initialize(path)
      @path = path
      @waiters = Hash.new
      @event_id = 0
      @@channels[path] = self
    end

    def transmit(id, params)
      @waiters.each do |signature, server|
        server.commit if server.respond(id, params)
      end
    end

    def join(server)
      @waiters[server.signature] = server
      server.commit
    end

    def leave(server)
      @waiters.delete(server.signature)
    end

    def self.[](channel); @@channels[channel] end
    def self.list; @@channels.keys end
    def self.sweep; @@channels.delete_if{|k,v| v.waiters.empty?} end

    def self.cleanup(channel)
      result = @@channels[channel] && @@channels[channel].waiters.empty?
      @@channels.delete(channel) if result
      result
    end
  end
end
