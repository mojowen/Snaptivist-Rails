class Signup < ActiveRecord::Base
  	attr_accessible :firstName, :lastName, :email, :zip, :twitter, :friends, :reps, :photo_date, :photo_path, :photo
	attr_accessor :photo
  	before_save :save_photo

  	def save_photo
  		# Upload to facebook asynchronously

  		unless photo.nil?
	  		File.open( "tmp/#{created_at}.png", 'wb') do |f|
	  			f.write( photo.read )
	  		end
	  		self.photo_path = "tmp/#{created_at}.png"
	  	end
	end
end
