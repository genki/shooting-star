class <%= class_name %>Controller < ApplicationController
  layout '<%= file_name %>', :only => :index

  def index
    @chats = <%= class_name %>.find(:all).reverse
  end

  def show
    @chat = <%= class_name %>.find(params[:id])
  end

  def talk
    @chat = <%= class_name %>.create!(params[:chat])
    content = render_component_as_string :action => 'show', :id => @chat.id
    javascript = render_to_string :update do |page|
      page.insert_html :top, 'chat-list', content
    end
    Meteor.shoot '<%= file_name %>', javascript
    render :update do |page|
      page[:chat_message].clear
      page[:chat_message].focus
    end
  end
end
