require 'shooting_star/channel'

# DRbObject
module ShootingStar
  class Shooter
    # broadcast/multicast message
    def shoot(channel_path, id, tag, options = {})
      return unless Channel[channel_path]
      tag ||= []
      log{"Shot: #{channel_path}:#{id}:#{tag.join(',')}:#{options}"}
      Channel[channel_path].transmit(id, options.merge(:tag => tag))
    end

    # update client properties
    def update(sig, uid, tag)
      ::ShootingStar::Server[sig].update(uid, tag || [])
    rescue Exception
    end

    def signature; ShootingStar::timestamp end
    def channels; Channel.list end
    def observers; Channel.observers end
    def sweep; Channel.sweep end

    # count up listeners
    def count(channel_path, tag = nil)
      servers(channel_path, tag).size
    end

    # count up listeners with specified user.
    def count_with(sig, channel_path, tag = nil)
      (signatures(channel_path, tag) | [sig]).size
    end

    # lookup listeners
    def listeners(channel_path, tag = nil)
      servers(channel_path, tag).map{|s| s.uid}
    end

    # lookup listeners with specified user.
    def listeners_with(uid, sig, channel_path, tag = nil)
      servers(channel_path, tag).inject([uid]) do |result, server|
        result << server.uid unless server.signature == sig
        result
      end
    end

    # lookup signatures on specified channel.
    def signatures(channel_path, tag = nil)
      servers(channel_path, tag).map{|s| s.signature}
    end

    # observe server side events
    def observe(channel_path, observer)
      Channel.observe(channel_path, observer)
    rescue Exception 
    end

  private
    def log(&block) ShootingStar::log(&block) end

    def servers(channel_path, tag = nil)
      return [] unless Channel[channel_path]
      result = Channel[channel_path].waiters.values
      if tag && !tag.empty?
        result = result.select do |server|
          server.tag.empty? || !(server.tag & tag).empty?
        end 
      end
      result
    end
  end
end
