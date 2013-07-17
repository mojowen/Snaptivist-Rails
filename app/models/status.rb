class Status < ActiveRecord::Base
	attr_accessible :message, :target, :signup, :photo_path, :data, :target

	belongs_to :signup

	serialize :data, JSON

	def send_tweet

		# begin
			if photo_path.nil? && ! signup.photo_path.nil? #  Check and see if this status does not have a photo BUT this signup DOES have a photo
				return 'over photo limit - skipping' unless Rails.cache.read('no_upload').nil?

				require 'RMagick'
				image = Magick::ImageList.new
				image.from_blob( open( signup.photo_path.split('?')[0] ).read )
				image = image.resize(600,450)

				self.data = Twitter.update_with_media( self.message, image.to_blob )
				signup.statuses.reject{ |s| s == self }.each{ |s| s.update_attributes( :photo_path => self.data['entities']['media'].first['url'] ) } # Attach the photo URL - already uplaoded to twitter

			else # Photo path is set or there's no photo - either way not doing a media post

				self.message += ' '+self.photo_path unless self.photo_path.nil? # Attach photo URL if set
				self.data = Twitter.update(message)

			end

			self.sent = true
			self.save
			return 'Tweet Success'
		# rescue => e
		# 	return "Tweet Fail\nError: #{e}\nData:#{self.message} #{self.signup.photo_path}"

		# 	if "#{e}".index('daily photo limit')
		# 		Rails.cache.write('no_upload',true,:expires_in => 3.hours)
		# 	else
		# 		self.sent = true
		# 		self.data = { :error => e }
		# 		self.save
		# 	end
		# end

	end
	def sender
		return signup.twitter unless signup.twitter.nil? || signup.twitter.empty?
		return signup.firstName
	end
end
