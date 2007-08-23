class MeteorController < ApplicationController
  layout nil
  caches_action :strike

  def strike
    @channel = params[:channel]
    if params[:event].blank?
      meteor = Meteor.find(params[:id])
      @javascript = meteor.javascript
    else
      @javascript = %Q[setTimeout(function(){
        meteorStrike[#{@channel.to_json}].event(#{params.to_json});}, 0);]
    end
  end

  def update
    tags = (params[:tag] || '').split(',').map{|i| CGI.unescape(i)}
    Meteor.shooter.update(params[:sig], params[:uid], tags)
    render :nothing => true
  end

  def sweep
    Meteor.shooter.sweep
    render :nothing => true
  end
end
