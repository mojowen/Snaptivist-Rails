class CreateSignups < ActiveRecord::Migration
  def change
    create_table :signups do |t|

    	t.string :firstName
    	t.string :lastName
    	t.string :email
    	t.string :twitter
    	t.string :zip
    	t.text :friends
    	t.text :reps

    	t.string :photo_path

      	t.timestamps
    end
  end
end
