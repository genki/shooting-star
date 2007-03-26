class MeteorController < ApplicationController
  layout nil
  caches_action :strike
  after_filter :notify_execution, :only => :strike

  def strike
    @channel = params[:channel].split('/').map{|i| CGI.escape(i)}.join('/')
    if params[:event].blank?
      meteor = Meteor.find(params[:id])
      @javascript = meteor.javascript
    else
      @javascript = %Q[setTimeout(function(){
        meteorStrike.event[#{@channel.to_json}](#{params.to_json});}, 0);]
    end
  end

  def update
    tags = (params[:tag] || '').split(',').map{|i| CGI.unescape(i)}
    Meteor.shooter.update(params[:sig], params[:uid], tags)
    render :nothing => true
  end

  def sweep
    Meteor.shooter.sweep
  end

private
  def notify_execution
    Meteor.shooter.executed(params[:sig], params[:id])
  end
end
