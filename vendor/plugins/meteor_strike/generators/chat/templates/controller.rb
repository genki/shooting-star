class <%= class_name %>Controller < ApplicationController
  layout '<%= file_name %>', :only => :index
  skip_before_filter :verify_authenticity_token

  def index
    session[:name] ||= 'guest'
    @chats = <%= class_name %>.find(:all).reverse
  end

  def show
    @chat = <%= class_name %>.find(params[:id])
  end

  def listen
    session[:name] = params[:name]
    render :update do |page|
      page << <<-"EOH"
        meteorStrike['<%= file_name %>'].update(#{session[:name].to_json});
      EOH
    end
  end

  def talk
    @chat = <%= class_name %>.new(
      :name => session[:name], :message => params[:message])
    if @chat.save
      content = render_component_as_string :action => 'show', :id => @chat.id
      javascript = render_to_string :update do |page|
        page.insert_html :top, 'chat-list', content
      end
      Meteor.shoot '<%= file_name %>', javascript
      render :update do |page|
        page[:message].clear
        page[:message].focus
      end
    else
      render :nothing => true
    end
  end

  def event
    message = case params[:event]
    when 'init'; "connection established by #{params[:type]}."
    when 'enter'; "#{params[:uid]} joined."
    when 'leave'; "#{params[:uid]} left."
    end
    @chat = <%= class_name %>.new(
      :name => '(* system *)',
      :created_at => Time.now,
      :message => message)
    render :action => 'show'
  end
end
