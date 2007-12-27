class ChatsController < ApplicationController
  layout 'chats', :only => [:index]
  caches_page :show
  skip_before_filter :verify_authenticity_token

  def index
    @chats = Chat.find(:all, :limit => 10, :order => 'created_at DESC')
  end

  def show
    @chat = Chat.find(params[:id])
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = Chat.new(:name => params[:chat_name],
      :message => params[:chat_message])

    rjs = ''
    if @chat.save
      contents = render_component_as_string :controller => 'chats',
        :action => 'show', :id => @chat.id
      javascript = render_to_string :update do |page|
        page.insert_html :top, 'chat-list', contents
      end
      tags = params[:chat_tag].split(/\s+/)
      if session[:name] != @chat.name || session[:tags] != tags
        rjs << %Q{
          meteorStrike['simple_chat/chatroom'].update(
            #{@chat.name.to_json}, #{tags.to_json}
          );
        }
      end
      Meteor::shoot 'simple_chat/chatroom',
        javascript, tags, :except => [session[:name], @chat.name]
      rjs << javascript
      session[:name] = @chat.name
      session[:tags] = tags
    end
    render(:update){|page| page << rjs}
  end

  def connection
    @chat = Chat.new(:name => '* system *', :created_at => Time.now,
      :message => "connection established on #{params[:type]}.")
    render :action => 'show'
  end

  def user_list
    @names = Meteor.shooter.listeners("simple_chat/chatroom", session[:tags])
    @names |= [session[:name]]
    @names = @names.map{|name| name.blank? ? '(guest)' : name}
  end
end
