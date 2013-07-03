class CreateStatuses < ActiveRecord::Migration
  def change
    create_table :statuses do |t|

    	t.integer :signup_id
    	t.string :message
    	t.boolean :sent, :default => false
    	t.text :data, :default => '{}'
    	t.string :target
      t.string :photo_path

		t.timestamps
    end
  end
end
