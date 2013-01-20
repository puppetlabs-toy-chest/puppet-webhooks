class CreateEvents < ActiveRecord::Migration
  def up
    create_table :events do |t|
      t.string :name
      t.text :payload
      t.text :request
    end
  end

  def down
    drop_table :events
  end
end
