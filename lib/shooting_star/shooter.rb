require 'shooting_star/channel'

# DRbObject
module ShootingStar
  class Shooter
    def shoot(channel, id, tag)
      return unless Channel[channel]
      log "Shot: #{channel}:#{id}:#{tag.join(',')}"
      Channel[channel].transmit(id, :tag => tag)
    end

    def update(sig, uid, tag)
      ::ShootingStar::Server[sig].update(uid, tag || [])
    rescue Exception
    end

    def signature; ShootingStar::timestamp end
    def channels; Channel.list end
    def sweep; Channel.sweep end

    def count(channel, tag = nil)
      servers(channel, tag).size
    end

    def count_with(sig, channel, tag = nil)
      (signatures(channel, tag) | [sig]).size
    end

    def listeners(channel, tag = nil)
      servers(channel, tag).map{|s| s.uid}
    end

    def listeners_with(uid, sig, channel, tag = nil)
      servers(channel, tag).inject([uid]) do |result, server|
        result << server.uid unless server.signature == sig
        result
      end
    end

    def signatures(channel, tag = nil)
      servers(channel, tag).map{|s| s.signature}
    end

    def executed(sig, id)
      ::ShootingStar::Server[sig].executed(id)
    rescue Exception
    end

  private
    def log(*arg, &block) ShootingStar::log(*arg, &block) end

    def servers(channel, tag = nil)
      return [] unless Channel[channel]
      result = Channel[channel].waiters.values
      if tag && !tag.empty?
        result = result.select do |server|
          server.tag.empty? || !(server.tag & tag).empty?
        end 
      end
      result
    end
  end
end
