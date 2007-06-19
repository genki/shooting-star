require 'set'

module ShootingStar
  class Channel
    class InvalidIdError < StandardError; end
    attr_reader :path, :waiters
    @@channels = {}

    def initialize(path)
      @path = path
      @waiters = Hash.new
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

    def self.[](path); @@channels[path] end
    def self.list; @@channels.keys end
    def self.sweep; @@channels.delete_if{|k,v| v.waiters.empty?} end

    def self.cleanup(channel)
      if @@channels[channel] && @@channels[channel].waiters.empty?
        @@channels.delete(channel)
      end
      !@@channels.include?(channel)
    end
  end
end
