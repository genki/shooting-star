class Create<%= class_name.pluralize %> < ActiveRecord::Migration
  def self.up
    create_table '<%= file_name.pluralize %>' do |t|
      t.column :name, :string
      t.column :message, :text
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table '<%= file_name.pluralize %>'
  end
end
