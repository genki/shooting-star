require 'set'
require 'md5'

module MeteorStrike
  module Helper
    def self.included(base)
      base.class_eval do
        alias_method :form_tag_without_timestamp, :form_tag
        alias_method :form_tag, :form_tag_with_timestamp
      end
    end

    def meteor_strike(channel, options = {})
      if !options[:cache] && !@meteor_strike
        cc = controller.headers['Cache-Control'] || ''
        cc += ', ' unless cc.empty?
        cc += 'no-store, no-cache, must-revalidate, max-age=0, '
        cc += 'post-check=0, pre-check=0'
        controller.headers['Cache-Control'] = cc
      end
      if !!request.user_agent[/iPhone|iPod/]
        options[:noflash] = true
      end
      @meteor_strike = controller.install_meteor_strike
      config = Meteor::config
      server = Meteor::server
      shooting_star_uri = "#{server}/#{channel}"
      if config['random_subdomain'] && /[A-z]/ === server
        subdomain = (1..6).map{(rand(26)+?a).chr}.to_s
        shooting_star_uri = [subdomain, shooting_star_uri].join('.')
      end
      uri = url_for(:only_path => false).split('/')[0..2].join('/')
      uid = options[:uid] ? options[:uid].to_s : ''
      escaped_uid = CGI.escape(uid)
      tags = options[:tag] || []
      tag = tags.map{|i| CGI.escape(i.to_s)}.join(',')
      update_uri = "#{uri}/meteor/update"
      now = Time.now
      sig = "%d%06d" % [now.tv_sec, now.tv_usec]
      iframe_id = "meteor-strike-#{@meteor_strike}"
      host_port = (server.split(':') << '80')[0..1].join(':')
      flash_vars = ["channel=#{channel}", "tag=#{tag}", "uid=#{escaped_uid}",
        "sig=#{sig}", "base_uri=#{uri}", "server=#{host_port}",
        "heartbeat=#{options[:heartbeat]}", "debug=#{options[:debug].to_json}",
        "meteor_strike_id=#{@meteor_strike}"].join('&')
      unless options[:noflash]
        @flash_html = render :use_full_path => false,
          :file => File.join(PLUGIN_ROOT, 'views/flash.rhtml'),
          :locals => {:flash_vars => flash_vars}
      end
      render :file => File.join(PLUGIN_ROOT, 'views/xhr.rhtml'),
        :use_full_path => false, :locals => {:iframe_id => iframe_id,
        :shooting_star_uri => shooting_star_uri, :uri => uri,
        :channel => channel, :uid => uid, :tag => tag, :tags => tags,
        :sig => sig, :options => options, :update_uri => update_uri}
    end

  private
    # Workaround for Safari's strange behaviour after back navigation.
    # Safari never posts if form elements are not modified since back
    # navigation. So we append timestamp before submitting.
    def form_tag_with_timestamp(urlop = {}, options = {}, *arg, &block)
      options = options.stringify_keys
      (options['onsubmit'] ||= '').insert(0, %Q[
        if(!this.__ts__){
          var ts = document.createElement('input');
          ts.name = ts.id = '__ts__';
          ts.type = 'hidden';
          this.appendChild(ts);
        }
        this.__ts__.value = new Number(new Date()).toString(32);
      ]) unless /^get$/i === options['method']
      form_tag_without_timestamp(urlop, options, *arg, &block)
    end 
  end
end
