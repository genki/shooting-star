class CreateChats < ActiveRecord::Migration
  def self.up
    create_table :chats do |t|
      t.column :name, :string
      t.column :message, :text
      t.column :password, :string
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :chats
  end
end
