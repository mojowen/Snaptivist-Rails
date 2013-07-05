class Signup < ActiveRecord::Base

  	attr_accessible :firstName, :lastName, :email, :zip, :twitter, :photo_date, :complete,
  		:friends, :reps,
  		:photo_path, :facebook_photo, :source,
  		:sendTweet, :event, :photo

	attr_accessor :photo, :sendTweet, :event

  	has_many :statuses

  	before_save :save_photo, :set_source
  	def save_photo
  		unless complete
	  		unless photo.nil?
				store =  AWS::S3::S3Object.store(file_name, photo, 'tac')
		  		self.photo_path = AWS::S3::S3Object.url_for(file_name,'tac',:expires_in => 60 * 60 * 48 )
		  		self.photo = nil
		  	end
	  	end
	end
	def set_source
		self.source = event.gsub("\t"," ") if event && ! complete
	end


  	after_save :sync
	def sync
		unless complete
			Thread.new do
				unless self.photo_path.nil?
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
			album_title = "#{event_deets[2]}: #{event_deets[0]} in #{event_deets[1]}"
			album_description = "FUN. was in #{event_deets[1]} to play #{event_deets[2]}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
			photo_description = "Photo from FUN. at #{event_deets[2]} in #{event_deets[1]}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
		else
			album_title = "#{event_deets[0]} in #{event_deets[1]}"
			album_description = "FUN. was in #{event_deets[1]}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
			photo_description = "Photo from FUN. at #{event_deets[2]}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
		end

		token = RestClient.get('https://graph.facebook.com/oauth/access_token?client_id='+ENV['FACEBOOK']+'&client_secret='+ENV['FACEBOOK_SECRET']+'&grant_type=fb_exchange_token&fb_exchange_token='+ENV['TOKEN']).gsub!('access_token=','')

		ENV['TOKEN'] = token
		# page_token = 'https://graph.facebook.com/me/accounts?access_token='+token

		event = 'Ally Coalition Test Albumn'

		privacy = {'value' => 'CUSTOM', 'allow' => '40900695,577932694'}

		me = FbGraph::User.me( token )
		album = me.albums.find{|f| f.name == album_title }
		album = me.album!( :name => album_title, :privacy => privacy, :message => photo_description) if album.nil?

		# token = ENV['PAGE_TOKEN']
		# me = FbGraph::Page.new( ENV['PAGE_ID'], :access_token => token ).fetch
		# album = me.albums.find{|f| f.name == album_title }
		# album = me.album!( :name => album_title, :message => photo_description ) if album.nil?

		uploaded_photo = album.photo!( :url => photo_path, :message => photo_description, :token => token )

		facebook_photo = album.photos.find{ |fb_photo| fb_photo.identifier == uploaded_photo.identifier }

		self.facebook_photo = facebook_photo.link

		if does_send_tweets
			send_tweets
		else
			send_emails
		end
	end

	def does_send_tweets
		return ! self.reps.nil? && self.sendTweet && ! self.reps.empty?
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

		event_name = event_deets.length > 2 ? "@ #{event_deets[2]} in #{event_deets[1]}" : "in #{event_deets[1]}"

		if (self.zip.length != 5 rescue true ) && !self.facebook_photo.nil?
			WelcomeMailer.canadian( self.email, event_name, self.facebook_photo).deliver

			self.friends.split(',').each do |friend|
				WelcomeMailer.canadian( friend, event_name, self.facebook_photo).deliver
			end

		else
			if self.zip.length == 5 && self.sendTweet && self.reps.class == Array
				WelcomeMailer.us_tweet( self, event_name, self.facebook_photo ).deliver
			else
				WelcomeMailer.us_no_tweet( self.email, event_name, self.facebook_photo, self.zip ).deliver
			end

			self.friends.split(',').each do |friend|
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


end
