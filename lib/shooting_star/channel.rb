module ShootingStar
  class Channel
    attr_reader :path, :waiters
    @@channels = {}
    @@observers = Hash.new{|h,k| h[k] = Hash.new}

    def initialize(channel_path)
      @path = channel_path
      @waiters = Hash.new
      @@channels[path] = self
    end

    # A message is sent to observers if params includes a :event key.
    # If there are no observers, the message is sent to clients.
    # Others are sent to clients.
    def transmit(id, params)
      need_event_handling = false
      if event = params[:event]
        observers = @@observers.has_key?(@path) ? @@observers[@path].dup : nil
        observers.each do |name, obs|
          begin obs.__send__(event, params) if obs.respond_to?(event)
          rescue Exception; Channel.ignore(@path, name) end
        end if observers
        need_event_handling = observers.nil? || observers.empty?
      end
      if event.nil? || need_event_handling
        @waiters.each do |signature, server|
          server.commit if server.respond(id, params)
        end
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
    def self.observers; @@observers end

    def self.observe(channel_path, observer)
      @@observers[channel_path][observer.name] = observer
    end

    def self.ignore(channel_path, name)
      @@observers[channel_path].delete(name)
      @@observers.delete(channel_path) if @@observers[channel_path].empty?
    end

    def self.cleanup(channel_path)
      if @@channels[channel_path] && @@channels[channel_path].waiters.empty?
        @@channels.delete(channel_path)
      end
      !@@channels.include?(channel_path)
    end
  end
end
