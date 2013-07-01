class Signup < ActiveRecord::Base
  	attr_accessible :firstName, :lastName, :email, :zip, :twitter, :friends, :reps, :photo_date, :photo_path, :photo
	attr_accessor :photo
  	before_save :save_photo

  	def save_photo
  		# Store the image in dropbox
  		# Upload to facebook asynchronously

  		# unless photo.nil?
	  	# 	File.open( 'shipping_label.png', 'wb') do|f|
	  	# 		f.write( photo.read )
	  	# 	end
	  	# end
	end
end
