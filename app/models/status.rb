class Status < ActiveRecord::Base
	attr_accessible :message, :target, :signup, :photo_path, :data, :target

	belongs_to :signup

	serialize :data, JSON

	def self.fix_old_tweets
		tweets = File.read( Dir.glob('tmp-images/*').first ).split(/\r/)
		tweets.each do |tweet|
			status = Status.find_by_message_and_sent( tweet.split(',').first.split(' http://t.co/').first, false)
			begin
				if status
					status.match_tweet( tweet.split(',').last )
					sleep 10
				end
			rescue
			end
		end
	end

	def match_tweet status_id
		self.data = Twitter.status( status_id )
		self.sent = true
		self.signup.statuses.each{ |s| s.update_attributes( :photo_path => self.data.to_hash[:entities][:media].first[:url] ) } if self.data.to_hash[:entities][:media].first[:url] # Attach the photo URL - already uplaoded to twitter
		self.save
	end
	def zip
		return signup.zip
	end
	def sent_at
		 ( Time.parse( self.data['created_at'] || self.data[:created_at] ) rescue t.updated_at )
	end

	def send_tweet

		begin
			if photo_path.nil? && ! signup.photo_path.nil? #  Check and see if this status does not have a photo BUT this signup DOES have a photo
				return 'over photo limit - skipping' unless Rails.cache.read('no_upload').nil?

				require 'RMagick'
				image = Magick::ImageList.new
				begin
					image.from_blob( open( signup.photo_path.split('?')[0] ).read )
				rescue
					# Try facebook for the image
					facebook = JSON::parse( RestClient.get( 'https://graph.facebook.com/'+signup.facebook_photo.split('fbid=').last ))
					image.from_blob( open( facebook['source'] ).read )
				end
				image = image.resize(600,450)
				file_name = './tmp-images/'+ signup.photo_path.split('?')[0].split('/').last
				image.write( file_name )

				self.data = Twitter.update_with_media( self.message, File.new( file_name ) )
				self.signup.statuses.each{ |s| s.update_attributes( :photo_path => self.data.to_hash[:entities][:media].first[:url] ) } if self.data.to_hash[:entities][:media].first[:url] # Attach the photo URL - already uplaoded to twitter

			else # Photo path is set or there's no photo - either way not doing a media post

				self.message += ' '+self.photo_path unless self.photo_path.nil? # Attach photo URL if set
				self.data = Twitter.update(message)

			end

			self.sent = true
			self.save
			return 'Tweet Success'
		rescue => e

			if "#{e}".index('daily photo limit')
				Rails.cache.write('no_upload',true,:expires_in => 3.hours)
			else
				self.sent = true
				self.data = { :error => e }
				self.save
			end

			return "Tweet Fail\nError: #{e}\nData:#{self.message} #{self.signup.photo_path}"
		end

	end
	def sender
		return signup.twitter unless signup.twitter.nil? || signup.twitter.empty?
		return signup.firstName
	end
end
