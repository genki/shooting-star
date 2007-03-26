class ChatsController < ApplicationController
  layout 'chats', :only => [:index]
  caches_page :show

  def index
    @chats = Chat.find(:all, :limit => 50, :order => 'created_at DESC')
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

    if @chat.save
      contents = render_component_as_string :controller => 'chats',
        :action => 'show', :id => @chat.id
      javascript = render_to_string :update do |page|
        page.insert_html :top, 'chat-list', contents
      end
      tags = params[:chat_tag].split(/\s+/)
      if session[:name] != @chat.name || session[:tags] != tags
        session[:name] = @chat.name
        session[:tags] = tags
        render :update do |page|
          page << "meteorStrike.update(#{@chat.name.to_json}, #{tags.to_json})"
        end
      end
      Meteor::shoot 'simple_chat/chatroom', javascript, tags
    end
    render :nothing => true unless performed?
  end

  def user_list
    @names = Meteor.shooter.listeners("simple_chat/chatroom", session[:tags])
    @names |= [session[:name]]
    @names = @names.map{|name| name.blank? ? '(guest)' : name}
  end
end
