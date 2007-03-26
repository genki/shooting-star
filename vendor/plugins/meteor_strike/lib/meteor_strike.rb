require 'uri'
require 'md5'

module MeteorStrike
  module Helper
    def meteor_strike(channel, options = {})
      unless options[:cache] || @meteor_strike
        cc = controller.headers['Cache-Control'] || ''
        cc += ', ' unless cc.empty?
        cc += 'no-store, no-cache, must-revalidate, max-age=0, '
        cc += 'post-check=0, pre-check=0'
        controller.headers['Cache-Control'] = cc
        @meteor_strike = true
      end
      config = ActiveRecord::Base.configurations[RAILS_ENV]
      shooting_star_uri = "#{config['shooting_star']['server']}/#{channel}"
      uri = url_for(:only_path => false).split('/')[0..2].join('/')
      uid = options[:uid] ? CGI.escape(options[:uid].to_s) : ''
      tags = options[:tag] || []
      tag = tags.map{|i| CGI.escape(i.to_s)}.join(',')
      base_uri = "http://#{shooting_star_uri}?execute=#{uri}/meteor/strike"
      update_uri = "#{uri}/meteor/update"
      sig = Meteor.shooter.signature
      <<-"EOH"
      <script type="text/javascript">
      //<[CDATA[
      var meteorStrike;
      Event.observe(window, 'load', function(){
        var channel = #{channel.to_json};
        var UID = #{uid.to_json}, TAGS = #{tags.to_json};
        var encodeTags = function(tags){
          var encode = function(i){return encodeURIComponent(i)};
          return $A(tags).uniq().map(encode).join(',');
        };
        meteorStrike = meteorStrike || new Object;
        meteorStrike.execute = function(js){eval(js)};
        meteorStrike.event = meteorStrike.event || $H();
        meteorStrike.event[channel] = function(params){#{options[:event]}};
        meteorStrike.update = function(uid, tags){
          new Ajax.Request([#{update_uri.to_json},
            '?channel=', channel,
            '&uid=', uid || UID,
            '&tag=', encodeTags(tags || TAGS),
            '&sig=', #{sig.to_json}].join(''));
          UID = uid, TAGS = tags;
        };
        meteorStrike.tuneIn = function(tags){
          meteorStrike.update(UID, TAGS.concat(tags).uniq());
        };
        meteorStrike.tuneOut = function(tags){
          meteorStrike.update(UID, Array.prototype.without.apply(TAGS, tags));
        };
        setTimeout(function(){ 
          var iframe = document.createElement('iframe');
          iframe.src = ["#{base_uri}&uid=#{uid}&tag=#{tag}&sig=#{sig}",
            '&__ts__=', new Number(new Date()).toString(32)].join('');
          iframe.frameborder = "0";
          iframe.width = "0";
          iframe.height = "0";
          iframe.style.border = '0px';
          document.body.appendChild(iframe);
          setTimeout(function(){#{options[:connected]}}, 0);
        }, 0);
      });
      //]]>
      </script>
      EOH
    end
  end
end
