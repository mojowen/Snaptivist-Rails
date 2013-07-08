class Signup < ActiveRecord::Base

  	attr_accessible :firstName, :lastName, :email, :zip, :twitter, :photo_date, :complete,
  		:friends, :reps,
  		:photo_path, :facebook_photo, :source,
  		:sendTweet, :event, :photo, :uploaded_photo

	validates_presence_of :email, :firstName, :zip

	attr_accessor :photo, :sendTweet, :event, :uploaded_photo

  	has_many :statuses

  	before_save :save_photo, :set_source, :handle_webform
  	def save_photo
		uploaded_photo = false
  		unless complete
	  		unless photo.nil?
	  			f = File.open( file_path,'w')
	  			f.write( photo )
	  			f.close()
	  			uploaded_photo = true
		  	end
	  	end
	end
	def set_source
		self.source = event.gsub("\t"," ") if event && ! complete
	end
	def handle_webform
		if (self.source || '' ).downcase == 'webform'
			save_to_fanbridge
			self.complete = true
			self.photo_date = DateTime.now
		end
	end


  	after_save :sync
	def sync
		unless complete
			Thread.new do
				unless uploaded_photo
					puts 'file uploading to aws'
					file = File.open( file_name,'r' )
					store =  AWS::S3::S3Object.store(file_name, file, 'tac')
					file.close()
			  		self.photo_path = AWS::S3::S3Object.url_for(file_name,'tac',:expires_in => 60 * 60 * 48 )
			  		puts 'file uploading to facebook'
					send_photo_to_facebook
				else
					if does_send_tweets
						send_tweets
					else
						send_emails
					end
				end
				save_to_fanbridge
				self.complete = true
				self.reps = self.reps.map{|r| r['bioguide'] }.join(',') if self.reps.class == Array
				self.save
			end
		end
	end


	def send_photo_to_facebook

		event_deets = self.event.split("\t").map{|s| s.strip }.reject{ |s| s.nil? || s.empty? }

		if event_deets.length == 3
			city = event_deets[1].split(', ')[0]
			album_title = "#{event_deets[2]}: #{event_deets[0]} in #{city}"
			album_description = "FUN. was in #{city} to play #{event_deets[2]}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
			photo_description = "Photo from FUN. at #{event_deets[2]} in #{city}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
		else
			city = event_deets[1].split(', ')[0]
			album_title = "#{event_deets[0]} in #{city}"
			album_description = "FUN. was in #{city}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
			photo_description = "Photo from FUN. at #{event_deets[2]}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
		end

		page_token = Rails.cache.read('page_token') || ENV['PAGE_TOKEN']

		begin
			me = FbGraph::Page.new( ENV['PAGE_ID'], :access_token => page_token ).fetch
		rescue
			token = RestClient.get('https://graph.facebook.com/oauth/access_token?client_id='+ENV['FACEBOOK']+'&client_secret='+ENV['FACEBOOK_SECRET']+'&grant_type=fb_exchange_token&fb_exchange_token='+ENV['TOKEN']).gsub!('access_token=','')
			page_token = JSON::parse( RestClient.get('https://graph.facebook.com/me/accounts?access_token='+token) )
			page_token = page_token['data'].find{ |f| f['id'] == ENV['PAGE_ID']}['access_token']
			Rails.cache.write('page_token',page_token)

			me = FbGraph::Page.new( ENV['PAGE_ID'], :access_token => page_token ).fetch
		end

		album = me.albums.find{|f| f.name == album_title }
		album = me.album!( :name => album_title, :message => photo_description, :token => ENV['PAGE_TOKEN'] ) if album.nil?

			uploaded_photo = album.photo!( :url => photo_path, :message => photo_description, :token => ENV['PAGE_TOKEN'] )

		facebook_photo = album.photos.find{ |fb_photo| fb_photo.identifier == uploaded_photo.identifier }

		self.facebook_photo = facebook_photo.link

		if does_send_tweets
			send_tweets
		else
			send_emails
		end
	end

	def does_send_tweets
		return ! self.reps.nil? && ! self.reps.empty? && ( self.sendTweet.to_i != 0 rescue false)
	end

	def send_tweets
		#  Use SoundOff's find reps method to find reps with the bioguides
		if self.reps.class == String
			self.reps = JSON::parse( RestClient.get('http://www.soundoffatcongress.org/find_reps?bio='+self.reps ) )
		end
		reps.each{ |rep| enqueue_tweet( rep ) }
		send_emails
	end

	def send_emails
		event_deets = self.event.split("\t").map{|s| s.strip }.reject{ |s| s.nil? || s.empty? }
		event_name = event_deets[1].split(', ').first

		if (self.zip.length != 5 rescue true ) && !self.facebook_photo.nil?
			WelcomeMailer.canadian( self.email, event_name, self.facebook_photo).deliver

			(self.friends || '').split(',').each do |friend|
				WelcomeMailer.canadian( friend, event_name, self.facebook_photo).deliver
			end

		else
			if self.zip.length == 5 && self.sendTweet && self.reps.class == Array
				WelcomeMailer.us_tweet( self, event_name, self.facebook_photo ).deliver
			else
				WelcomeMailer.us_no_tweet( self, event_name, self.facebook_photo ).deliver
			end

			(self.friends || '').split(',').each do |friend|
				WelcomeMailer.us_no_tweet( friend, event_name, self.facebook_photo ).deliver
			end
		end

	end
	def save_to_fanbridge
		return false
		params = {}
		params['firstName'] = firstName
		params['lastname'] = lastName
		params['email'] = email
		params['zip'] = zip
		params['twitter_url'] = twitter
		fanbridge_send params
		friends.split(",").each{ |e| fanbridge_send( {'email' => e } ) } unless self.friends.nil?
	end


	#  Helper functions
	def enqueue_tweet rep
		user = twitter.nil? || twitter.empty? ? "#{firstName}" : '@'+twitter

		if rep['chamber'] == 'house'
			message = "@#{rep['twitter_screen_name']} #{user} from your district asks you to sponsor Safe Schools HR1625/HR1199 #MostNights #SoundOff"
		else
			message = "@#{rep['twitter_screen_name']} #{user} from your district asks you to sponsor Safe Schools S403/S1088 #MostNights #SoundOff"
		end

		self.statuses.new({ :message => message, :target => rep['twitter_screen_name'] }).save
	end
	def fanbridge_send params={}
		form = 'http://www.fanbridge.com/signup/fansignup_form.php?userid=177433'

		RestClient.post( form, params ){|response, request, result|  response }
	end
  	def file_name
		[firstName,lastName,photo_date].join('_')+'.png'
  	end
  	def file_path
  		'cache/'+file_name
  	end
  	def friend_count
  		return (friends || '').split(',').count
  	end
  	def tweet_count
  		return statuses.reject{ |d| d.data.empty? }.count
  	end
  	def zip_code
  		return zip
  	end
end
