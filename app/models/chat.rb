class Chat < ActiveRecord::Base
  validates_presence_of :name, :message
end
