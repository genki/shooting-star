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
    class MethodNotAcceptable < StandardError; end

    attr_reader :signature, :type
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
      return send_policy_file if @data.length == 0 &&
        data == "<policy-file-request/>"
      @data += data
      header, body = @data.split(/\n\n|\r\r|\n\r\n\r|\r\n\r\n/, 2)
      return unless body
      data = @data
      headers = header.split(/[\n\r]+/)
      head = headers.shift
      method, path, protocol = head.split(/\s+/)
      raise MethodNotAcceptable unless method.downcase == 'post'
      # recognize header
      hdr = headers.inject({}) do |hash, line|
        key, value = line.split(/ *?: */, 2)
        hash[key.downcase] = value if key
        hash
      end
      # check data arrival
      return if body.length < hdr['content-length'].to_i
      @data = ''
      # recognize parameter
      @params = Hash.new
      body.split('&').each do |item|
        key, value = item.split('=', 2)
        @params[key] = CGI.unescape(value) if value && value.length > 0
      end
      # load or create session informations
      @signature ||= @params['sig']
      channel_path = path[1..-1].split('?', 2)[0]
      @channel_path ||= CGI.unescape(channel_path)
      @query = "channel=#{channel_path}&sig=#{@signature}"
      @type = @params['__t__']
      # process verb
      if !@type
        make_connection(path)
      else
        prepare_channel(@channel_path)
        @uid = @@uids[@signature] ||= @params['uid']
        @tag = @@tags[@signature] ||=
          (@params['tag'] || '').split(',').map{|i| CGI.unescape(i)}
        unless @@servers[@signature] || @type == 'rc'
          notify(:event => :enter, :uid => @uid, :tag => @tag)
          log "Connected: #{@uid}"
        end
        @executing = @@executings[@signature] ||= Hash.new
        @@servers[@signature] = self
        wait_for
      end
    rescue MethodNotAcceptable
      write_and_close
    rescue Exception => e
      log "ERROR: #{e.message}\n#{e.backtrace.join("\n")}\n#{data}"
      write_and_close
    end

    # detect disconnection from the client and clean it up.
    def unbind
      @unbound = true
      if channel = Channel[@channel_path]
        channel.leave(self)
        notify(:event => :leave, :uid => @uid, :tag => @tag)
      end
      @@servers.delete(@signature)
      @@uids.delete(@signature)
      @@tags.delete(@signature)
      @@executings.delete(@signature)
      log "Disconnected: #{@uid}:#{@signature}"
      if Channel.cleanup(@channel_path)
        log "Channel closed: #{@channel_path}"
      end
    end

    # respond to an execution command.
    def respond(id, params)
      return unbind && false if !@waiting && session_timeout?
      @executing = @@executings[@signature] ||= Hash.new
      if params[:tag] && !params[:tag].empty? && !@tag.empty?
        return false if (params[:tag] & @tag).empty?
      end
      @executing[id] = params
      @waiting
    end

    # perform buffered executions.
    def commit
      return false if @unbound || !@waiting
      @executing.each{|id, params| execute(id, params)}
      return false if @execution.empty?
      return false unless send_data(@type == 'f' ? "#{@execution}\0" :
        "HTTP/1.1 200 OK\nContent-Type: text/javascript\n\n#{@execution}")
      @committed_at = Time.now
      @execution = ''
      @executing = Hash.new
      @@executings.delete(@signature)
      unless @type == 'f'
        @waiting = nil
        write_and_close
      end
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

    # accessor which maps signatures to servers.
    def self.[](signature)
      @@servers[signature]
    end

  private
    def log(*arg, &block) ShootingStar::log(*arg, &block) end

    # check session timeout
    def session_timeout?
      return true unless @committed_at
      Time.now - @committed_at > ShootingStar::CONFIG.session_timeout
    end

    # broadcast event to clients.
    def notify(params = {})
      return unless Channel[@channel_path]
      event_id = ShootingStar::timestamp
      log "Event(#{event_id}): #{@channel_path}:#{params.inspect}"
      Channel[@channel_path].transmit("event-#{event_id}", params)
    rescue Exception => e
      log "ERROR: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    # wait for commands or events until they occur. if they're already in
    # the execution buffer, they'll be flushed and return on the spot.
    def wait_for
      @waiting = true
      log "Wait for: #{@channel_path}:#{@uid}:#{@tag.join(',')}:#{@signature}"
      if prepare_channel(@channel_path).join(self)
        log "Flushed: #{@channel_path}:#{@uid}:#{@tag.join(',')}:#{@signature}"
      end
    end

    # prepare channel object.
    def prepare_channel(channel_path)
      unless Channel[channel_path]
        Channel.new(channel_path)
        log "Channel opened: #{channel_path}"
      end
      Channel[channel_path]
    end

    # add execution line to the buffer.
    def execute(id, params)
      sweep_timeout = ShootingStar::CONFIG.sweep_timeout
      @executing[id] = params
      query = @query.sub(%r[\&sig=\d+], '')
      query += "&" + FormEncoder.encode(params) if params
      @execution += <<-"EOH"
      (function(){
        var ms1 = document.getElementById('meteor-strike-1');
        var box = ms1 ? ms1.parentNode : document.body;
        var iframe = document.createElement('iframe');
        var remove = function(){box.removeChild(iframe)};
        var timer = setTimeout(remove, #{sweep_timeout});
        iframe.onload = function(){
          clearTimeout(timer);
          setTimeout(remove, 0);
        };
        iframe.src = '#{@params['execute']}/#{id}?#{query}';
        box.appendChild(iframe);
      })();
      EOH
    end

    # make client connect us.
    def make_connection(path)
      assets = URI.parse(@params['execute'])
      assets.path = '/javascripts/prototype.js'
      assets.query = assets.fragment = nil
      query = @query.sub(%r[\&sig=\d+], '')
      query += "&" + FormEncoder.encode(:event => :init, :type => :xhr)
      send_data "HTTP/1.1 200 OK\nContent-Type: text/html\n\n" +
      <<-"EOH"
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
      <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"><head>
      <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
      <script type="text/javascript" src="#{assets}"></script>
      <script type="text/javascript">
      //<![CDATA[
      var connect = function(reconnect)
      { var body = $H(#{@params.to_json});
        body.__t__ = reconnect ? 'rc' : 'c';
        var request = new Ajax.Request(#{path.to_json},
          {evalScript: true, onComplete: function(xhr){
            setTimeout(function(){connect(true)},
              xhr.getResponseHeader('Content-Type') ? 0 : 3000);
          }, postBody: body.toQueryString()});
        var disconnect = function()
        { request.options.onComplete = function(){};
          request.transport.abort();
        };
        Event.observe(window, 'unload', disconnect);
      };
      setTimeout(function(){connect(false)}, 0);
      //]]>
      </script></head><body>
        <iframe src="#{@params['execute']}/0?#{query}"></iframe>
      </body></html>
      EOH
    rescue Exception
    ensure
      write_and_close
    end

    # respond to policy file request.
    def send_policy_file
      send_data <<-"EOH" + "\0"
      <cross-domain-policy>
        <allow-access-from domain="*" to-ports="*" />
      </cross-domain-policy>
      EOH
      write_and_close
    end
  end
end
