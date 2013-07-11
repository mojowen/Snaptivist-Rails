class Status < ActiveRecord::Base
	attr_accessible :message, :target, :signup, :photo_path, :data, :target

	belongs_to :signup

	serialize :data, JSON

	def send_tweet

		# begin
		  	if photo_path.nil? && ! signup.photo_path.nil? #  Check and see if this status does not have a photo BUT this signup DOES have a photo
				require 'RMagick'
		  		photo = open( signup.photo_path) # If not - download it from facebook
				image = Magick::ImageList.new
				image.from_blob(photo.read)
				image.resize_to_fit(600,450)
		  		# begin
			  		self.data = Twitter.update_with_media( self.message, image )
				  	signup.statuses.reject{ |s| s == self }.each{ |s| s.update_attributes( :photo_path => self.data.media.first[:url] ) } # Attach the photo URL - already uplaoded to twitter
			  	# rescue
			  	# 	self.data = Twitter.update( self.message )
			  	# end

			else # Photo path is set or there's no photo - either way not doing a media post

				self.message += ' '+self.photo_path unless self.photo_path.nil? # Attach photo URL if set
				self.data = Twitter.update(message)

			end
		# rescue
		# end

		self.sent = true
		self.save
	end
	def sender
		return signup.twitter unless signup.twitter.nil? || signup.twitter.empty?
		return signup.firstName
	end
end
