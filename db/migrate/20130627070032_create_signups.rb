class CreateSignups < ActiveRecord::Migration
  def change
    create_table :signups do |t|

    	t.string :firstName
    	t.string :lastName
    	t.string :email
    	t.string :twitter
    	t.string :zip
      t.date :photo_date

      t.text :friends
      t.text :reps

      t.string :source
    	t.string :photo_path
      t.string :facebook_photo

      t.boolean :complete, :default => false

    	t.timestamps
    end
  end
end
