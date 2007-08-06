module ShootingStar
  class Channel
    attr_reader :path, :waiters
    @@channels = {}
    @@observers = Hash.new{|h,k| h[k] = Hash.new}
    @@mutex = Mutex.new

    def initialize(channel_path)
      @path = channel_path
      @waiters = Hash.new
      @@channels[path] = self
    end

    def transmit(id, params)
      if event = params[:event]
        observers = @@mutex.synchronize do
          @@observers.has_key?(@path) ? @@observers[@path].dup : nil
        end
        observers.each do |name, obs|
          begin obs.__send__(event, params) if obs.respond_to?(event)
          rescue Exception; Channel.ignore(@path, obs) end
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
      @@mutex.synchronize{@@observers[channel_path][observer.name] = observer}
    end

    def self.ignore(channel_path, observer)
      @@mutex.synchronize do
        @@observers[channel_path].delete(observer.name)
        @@observers.delete(channel_path) if @@observers[channel_path].empty?
      end
    end

    def self.cleanup(channel_path)
      if @@channels[channel_path] && @@channels[channel_path].waiters.empty?
        @@channels.delete(channel_path)
      end
      !@@channels.include?(channel_path)
    end
  end
end
