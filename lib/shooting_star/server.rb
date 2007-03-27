require 'json'
require 'cgi'
require 'uri'
require 'md5'
require 'set'
require 'form_encoder'

module ShootingStar
  # The module which will be included by servant who was born in the Asteroid.
  # This idea is from EventMachine.
  module Server
    attr_reader :signature
    @@servers = {}
    @@uids = {}
    @@tags = {}
    @@executings = {}

    # initialize servant waked up.
    def post_init
      @execution = ''
      @data = ''
    end

    # receive the data sent from client.
    def receive_data(data)
      @data += data
      response if @data[-4..-1] == "\r\n\r\n"
    end

    # detect disconnection from the client and clean it up.
    def unbind
      @unbound = true
      if channel = Channel[@channel]
        channel.leave(self)
        notify(:event => :leave, :uid => @uid, :tag => @tag)
        Channel.cleanup(@channel)
      end
      @@servers.delete(@signature)
      @@uids.delete(@signature)
      @@tags.delete(@signature)
      @@executings.delete(@signature)
      log "Disconnected: #{@uid}"
    end

    # respond to an execution command. it'll be buffered.
    def respond(id, params)
      @executing = @@executings[@signature] ||= Hash.new
      if params[:tag] && !params[:tag].empty? && !@tag.empty?
        return false if (params[:tag] & @tag).empty?
      end
      @executing[id] = params
      @waiting
    end

    # perform buffered executions.
    def commit
      return false if @unbound
      @executing.each{|id, params| execute(id, params)}
      return false if @execution.empty?
      send_data "HTTP/1.1 200 OK\nContent-Type: text/javascript\n\n"
      send_data @execution
      @waiting = nil
      @execution = ''
      @executing = Hash.new
      @@executings.delete(@signature)
      write_and_close
      true
    end

    # noticed execution and remove the command from execution buffer.
    def executed(id) 
      @executing = @@executings[@signature] ||= Hash.new
      @executing.delete(id)
    end
    
    # update current status of servant.
    def update(uid, tag)
      if @uid != uid || @tag != tag
        notify(:event => :leave, :uid => @uid, :tag => @tag)
        @@uids[@signature] = @uid = uid
        @@tags[@signature] = @tag = tag
        notify(:event => :enter, :uid => @uid, :tag => @tag)
      end
      log "Update: #{@uid}:#{@tag.join(',')}"
    end

    def uid; @@uids[@signature] end
    def tag; @@tags[@signature] end

    # an accessor which maps signatures to servers.
    def self.[](signature)
      @@servers[signature]
    end

  private
    def log(*arg, &block) ShootingStar::log(*arg, &block) end

    # broadcast an event to clients.
    def notify(params = {})
      return unless Channel[@channel]
      event_id = ShootingStar::timestamp
      log "Event(#{event_id}): #{@channel}:#{params.inspect}"
      Channel[@channel].transmit("event-#{event_id}", params)
    end

    # wait for commands or events until they occur. if they're already in
    # the execution buffer, they'll be flushed and return on the spot.
    def wait_for
      log "Wait for: #{@channel}:#{@uid}:#{@tag.join(',')}"
      if Channel[@channel].join(self)
        log "Flushed: #{@channel}:#{@uid}:#{@tag.join(',')}"
      end
      @waiting = true
    end

    # clean up channel and it'll be closed if no one's listening.
    def cleanup(channel)
      if Channel.cleanup(channel)
        log "Channel closed: #{@channel}"
      end
    end

    # give a response to the request or keep them waiting.
    def response
      headers = @data.split("\n")
      head = headers.shift
      method, path, protocol = head.split(/\s+/)
      # recognize header
      hdr = headers.inject({}) do |hash, line|
        key, value = line.chop.split(/ *?: */, 2)
        hash[key.downcase] = value if key
        hash
      end
      # recognize parameter
      @params = Hash.new
      if @query = path.split('?', 2)[1]
        if @query = @query.split('#', 2)[0]
          @query.split('&').each do |item|
            key, value = item.split('=', 2)
            @params[key] = CGI.unescape(value) if value && value.length > 0
          end
        end
      end
      # load or create session informations
      @signature ||= @params['sig']
      @channel ||= path[1..-1].split('?', 2)[0]
      @uid = @@uids[@signature] ||= @params['uid']
      @tag = @@tags[@signature] ||=
        (@params['tag'] || '').split(',').map{|i| CGI.unescape(i)}
      @executing = @@executings[@signature] ||= Hash.new
      @@servers[@signature] = self
      @query = "channel=#{@channel}&sig=#{@signature}"
      # prepare channel
      unless Channel[@channel]
        Channel.new(@channel)
        log "Channel opened: #{@channel}"
      end
      # process verb
      if method == 'GET'
        make_connection(path)
        notify(:event => :enter, :uid => @uid, :tag => @tag)
        log "Connected: #{@uid}"
      else
        wait_for
      end
    rescue
      log "ERROR: #{$!.message}\n#{@data}"
      raise
    ensure
      @data = ''
    end

    # add execution line to the buffer.
    def execute(id, params)
      sweep_timeout = ShootingStar::CONFIG.sweep_timeout || 500_000
      @executing[id] = params
      @query += "&" + FormEncoder.encode(params) if params
      @execution += <<-"EOH"
      (function(){
        var iframe = document.createElement('iframe');
        var remove = function(){document.body.removeChild(iframe)};
        var timer = setTimeout(remove, #{sweep_timeout});
        iframe.onload = function(){clearTimeout(timer); setTimeout(remove, 0)};
        document.body.appendChild(iframe);
        iframe.src = '#{@params['execute']}/#{id}?#{@query}';
      })();
      EOH
    end

    # make client connect us.
    def make_connection(path)
      assets = URI.parse(@params['execute'])
      assets.path = '/javascripts/prototype.js'
      assets.query = assets.fragment = nil
      send_data "HTTP/1.1 200 OK\nContent-Type: text/html\n\n" +
      <<-"EOH"
      <html><head><script type="text/javascript" src="#{assets}"></script>
      <script type="text/javascript">
      //<![CDATA[
      var connect = function()
      { var request = new Ajax.Request(
          #{path.to_json}, {evalScript: true, onComplete: function(xhr){
            setTimeout(connect,
              xhr.getResponseHeader('Content-Type') ? 0 : 1000);
          }});
        var disconnect = function()
        { request.options.onComplete = function(){};
          request.transport.abort();
        };
        Event.observe(window, 'unload', disconnect);
      };
      setTimeout(connect, 0);
      //]]>
      </script></head><body></body></html>
      EOH
      write_and_close
    end
  end
end
