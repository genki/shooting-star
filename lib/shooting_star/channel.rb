require 'set'

module ShootingStar
  class Channel
    attr_reader :path, :waiters
    @@channels = {}
    @@observers = Hash.new{|h,k| h[k] = Set.new}
    @@mutex = Mutex.new

    def initialize(channel_path)
      @path = channel_path
      @waiters = Hash.new
      @@channels[path] = self
    end

    def transmit(id, params)
      if event = params[:event]
        @@mutex.lock
        observers = @@observers.has_key?(@path) ? @@observers[@path].dup : nil
        @@mutex.unlock
        observers.each do |obs|
          begin obs.__send__(event, params) if obs.respond_to?(event)
          rescue Exception
            @@mutex.synchronize{@@observers[@path].delete(obs)}
          end
        end if observers
      end
      @waiters.each do |signature, server|
        server.commit if server.respond(id, params)
      end
    end

    def join(server)
      @waiters[server.signature] = server
      server.commit
    end

    def leave(server) @waiters.delete(server.signature) end
    def self.[](channel_path) @@channels[channel_path] end
    def self.list; @@channels.keys end
    def self.sweep; @@channels.delete_if{|k,v| v.waiters.empty?} end
    def self.observers; @@mutex.synchronize{@@observers.dup} end

    def self.observe(channel_path, observer)
      @@mutex.synchronize{@@observers[channel_path] << observer}
    end

    def self.cleanup(channel_path)
      if @@channels[channel_path] && @@channels[channel_path].waiters.empty?
        @@channels.delete(channel_path)
      end
      !@@channels.include?(channel_path)
    end
  end
end
