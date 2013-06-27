class Signup < ActiveRecord::Base
  attr_accessible :firstName, :lastName, :email, :zip, :twitter, :friends, :reps, :photo_path
end
