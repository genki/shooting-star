require 'uri'
require 'md5'

module MeteorStrike
  module Helper
    def self.included(base)
      base.class_eval do
        alias_method_chain :form_tag, :timestamp
      end
    end

    def meteor_strike(channel, options = {})
      unless options[:cache] || @meteor_strike
        cc = controller.headers['Cache-Control'] || ''
        cc += ', ' unless cc.empty?
        cc += 'no-store, no-cache, must-revalidate, max-age=0, '
        cc += 'post-check=0, pre-check=0'
        controller.headers['Cache-Control'] = cc
        @meteor_strike = 0
      end
      @meteor_strike += 1
      config = ActiveRecord::Base.configurations[RAILS_ENV]
      shooting_star_uri = "#{config['shooting_star']['server']}/#{channel}"
      uri = url_for(:only_path => false).split('/')[0..2].join('/')
      uid = options[:uid] ? CGI.escape(options[:uid].to_s) : ''
      tags = options[:tag] || []
      tag = tags.map{|i| CGI.escape(i.to_s)}.join(',')
      update_uri = "#{uri}/meteor/update"
      sig = Meteor.shooter.signature
      iframe_id = "meteor-strike-#{@meteor_strike}"
      iframe_body = <<-"EOH"
      EOH
      <<-"EOH"
      <div style="position: absolute; top: -99999px; left: -99999px">
      <iframe id="#{iframe_id}" name="#{iframe_id}"></iframe>
      <form id="#{iframe_id}-form" target="#{iframe_id}" method="POST"
        action="http://#{shooting_star_uri}">
        <input name="execute" value="#{uri}/meteor/strike" />
        <input name="tag" /><input name="uid" /><input name="sig" />
      </form></div>
      <script type="text/javascript">
      //<![CDATA[
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
          new Ajax.Request(#{update_uri.to_json}, {postBody: $H({
            channel: channel, uid: uid || UID,
            tag: encodeTags(tags || TAGS), sig: #{sig.to_json}
          }).toQueryString()});
          UID = uid, TAGS = tags;
        };
        meteorStrike.tuneIn = function(tags){
          meteorStrike.update(UID, TAGS.concat(tags).uniq());
        };
        meteorStrike.tuneOut = function(tags){
          meteorStrike.update(UID, Array.prototype.without.apply(TAGS, tags));
        };
        setTimeout(function(){ 
          var form = $("#{iframe_id}-form");
          form.uid.value = #{uid.to_json};
          form.tag.value = #{tag.to_json};
          form.sig.value = #{sig.to_json};
          form.submit();
          setTimeout(function(){#{options[:connected]}}, 0);
        }, 0);
      });
      //]]>
      </script>
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
  end
end
