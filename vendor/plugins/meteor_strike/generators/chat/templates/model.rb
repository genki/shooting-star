class <%= class_name %> < ActiveRecord::Base
  validates_presence_of :name, :message
end
