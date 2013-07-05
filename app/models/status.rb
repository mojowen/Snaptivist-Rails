class Status < ActiveRecord::Base
	attr_accessible :message, :target, :signup, :photo_path, :data, :target

	belongs_to :signup

	serialize :data, JSON

	def send_tweet

	  	if photo_path.nil? && ! signup.photo_path.nil? #  Check and see if this status does not have a photo BUT this signup DOES have a photo

		  	if signup.photo_path # If the file is still in the tmp directory - use it
		  		photo = File.open( signup.photo_path )
		  	else
		  		photo = open( signup.photo_path) # If not - download it from facebook
		  	end

		  	self.data = Twitter.update_with_media( self.message, photo )
		  	signup.statuses.reject{ |s| s == self }.each{ |s| s.update_attributes( :photo_path => self.data.media.first[:url] ) } # Attach the photo URL - already uplaoded to twitter

		else # Photo path is set or there's no photo - either way not doing a media post

			self.message += ' '+self.photo_path unless self.photo_path.nil? # Attach photo URL if set
			self.data = Twitter.update(message)

		end

		self.sent = true
		self.save
	end

end
