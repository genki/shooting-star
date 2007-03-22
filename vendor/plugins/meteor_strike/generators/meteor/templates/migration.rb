class CreateMeteors < ActiveRecord::Migration
  def self.up
    create_table :meteors do |t|
      t.column :javascript, :text
      t.column :limit, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :meteors
  end
end
