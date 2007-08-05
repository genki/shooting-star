require 'set'
require 'md5'

module MeteorStrike
  module Helper
    def self.included(base)
      base.class_eval do
        alias_method_chain :form_tag, :timestamp
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
      @meteor_strike ||= 0 and @meteor_strike += 1
      config = Meteor::config
      server = Meteor::server
      shooting_star_uri = "#{server}/#{channel}"
      if config['random_subdomain'] && /[A-z]/ === server
        subdomain = (1..6).map{(rand(26)+?a).chr}.to_s
        shooting_star_uri = [subdomain, shooting_star_uri].join('.')
      end
      uri = url_for(:only_path => false).split('/')[0..2].join('/')
      uid = options[:uid] ? CGI.escape(options[:uid].to_s) : ''
      tags = options[:tag] || []
      tag = tags.map{|i| CGI.escape(i.to_s)}.join(',')
      update_uri = "#{uri}/meteor/update"
      sig = Meteor.shooter.signature
      iframe_id = "meteor-strike-#{@meteor_strike}"
      host_port = (server.split(':') << '80')[0..1].join(':')
      flash_vars = [
        "channel=#{channel}", "tag=#{tag}", "uid=#{uid}", "sig=#{sig}",
        "base_uri=#{uri}", "server=#{host_port}"].join('&')
      flash_html = flash_tag(flash_vars) unless options[:noflash]
      <<-"EOH"
      <div style="position: absolute; top: -99999px; left: -99999px">
      <iframe id="#{iframe_id}" name="#{iframe_id}"></iframe>
      <form id="#{iframe_id}-form" target="#{iframe_id}" method="POST"
        action="http://#{shooting_star_uri}">
        <input name="execute" value="#{uri}/meteor/strike" />
        <input name="tag" /><input name="uid" /><input name="sig" />
      </form>
      <script type="text/javascript">
      //<![CDATA[
      var meteorStrike = meteorStrike || $H();
      Event.observe(window, 'load', function(){
        var channel = #{channel.to_json};
        var UID = #{uid.to_json}, TAGS = #{tags.to_json};
        var encodeTags = function(tags){
          var encode = function(i){return encodeURIComponent(i)};
          return $A(tags).uniq().map(encode).join(',');
        };
        var ms = meteorStrike[channel] = meteorStrike[channel] || new Object;
        ms.getTags = function(){return TAGS};
        ms.getUid = function(){return UID};
        ms.execute = function(js){eval(js)};
        ms.event = function(params){#{options[:event]}};
        ms.update = function(uid, tags){
          new Ajax.Request(#{update_uri.to_json}, {postBody: $H({
            channel: channel, uid: uid || UID,
            tag: encodeTags(tags || TAGS), sig: #{sig.to_json}
          }).toQueryString(), asynchronous: true});
          UID = uid, TAGS = tags;
        };
        ms.tuneIn = function(tags){
          ms.update(UID, TAGS.concat(tags || []).uniq());
        };
        ms.tuneOut = function(tags){
          ms.update(UID, Array.prototype.without.apply(TAGS, tags));
        };
        ms.tuneInOut = function(tagsIn, tagsOut){
          var tags = TAGS.concat(tagsIn || []).uniq();
          ms.update(UID, Array.prototype.without.apply(tags, tagsOut));
        };
        ms.tuneOutIn = function(tagsOut, tagsIn){
          var tags = Array.prototype.without.apply(TAGS, tagsOut);
          ms.update(UID, tags.concat(tagsIn || []).uniq());
        };
        try{
          var noflash = #{options[:noflash].to_json};
          if(noflash || !flashVersion || flashVersion < 6){
            setTimeout(function(){ 
              var form = $("#{iframe_id}-form");
              form.uid.value = #{uid.to_json};
              form.tag.value = #{tag.to_json};
              form.sig.value = #{sig.to_json};
              form.submit();
              setTimeout(function(){#{options[:connected]}}, 0);
            }, 0);
          }
        }catch(e){}
      });
      function meteor_strike_#{@meteor_strike}_DoFSCommand(command, args){
        switch(command){
        case 'execute': eval(args); break;
        case 'event':
          if(args == 'connect') (function(){#{options[:connected]}})();
          break;
        }
      }
      if(navigator.appName && navigator.appName.indexOf("Microsoft") != -1 &&
        navigator.userAgent.indexOf("Windows") != -1 &&
        navigator.userAgent.indexOf("Windows 3.1") == -1)
      {
        document.write([
          '<script language="VBScript"\\>',
          'On Error Resume Next',
          ['Sub meteor_strike_', #{@meteor_strike},
           '_FSCommand(ByVal command, ByVal args)'].join(''),
          ['  Call meteor_strike_', #{@meteor_strike},
           '_DoFSCommand(command, args)'].join(''),
          'End Sub', '</script\\>'].join(#{"\n".to_json}));
      }
      //]]>
      </script>#{flash_html}</div>
      EOH
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

    def flash_tag(flash_vars)
      flash_code_base = ['http://fpdownload.macromedia.com/',
        'pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0'].join('')
      swf_path = File.join(RAILS_ROOT, 'public/meteor_strike.swf')
      swf_timestamp = File.mtime(swf_path).to_i
      <<-"EOH"
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
       codebase="#{flash_code_base}" width="0" height="0"
       id="meteor_strike_#{@meteor_strike}">
      <param name="allowScriptAccess" value="sameDomain" />
      <param name="FlashVars" value="#{flash_vars}" />
      <param name="movie" value="/meteor_strike.swf?#{swf_timestamp}" />
      <param name="menu" value="false" />
      <param name="quality" value="high" />
      <param name="devicefont" value="true" />
      <param name="bgcolor" value="#ffffff" />
      <embed src="/meteor_strike.swf?#{swf_timestamp}" menu="false"
       quality="high" devicefont="true" bgcolor="#ffffff" width="0" height="0"
       swLiveConnect="true" id="meteor_strike_#{@meteor_strike}"
       name="meteor_strike_#{@meteor_strike}" flashvars="#{flash_vars}"
       allowScriptAccess="sameDomain" type="application/x-shockwave-flash"
       pluginspage="http://www.macromedia.com/go/getflashplayer" />
      </object>
      EOH
    end
  end
end
