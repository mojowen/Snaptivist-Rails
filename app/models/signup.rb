class Signup < ActiveRecord::Base
  	attr_accessible :firstName, :lastName, :email, :zip, :twitter, :friends, :reps, :photo_date, :photo_path, :photo, :sendTweet, :event, :facebook_photo_link
	attr_accessor :photo, :sendTweet, :event, :facebook_photo_link
  	before_save :save_photo
  	after_save :sync

  	has_many :statuses

  	def file_name
		[firstName,lastName,photo_date].join('_')+'.png'
  	end

  	def save_photo

  		unless photo.nil?
			store =  AWS::S3::S3Object.store(file_name, photo, 'tac')
	  		self.photo_path = AWS::S3::S3Object.url_for(file_name,'tac',:expires_in => 60 * 60 * 48 )
	  	end
	end

	def sync
		# Launch new thread
		send_photo_to_facebook unless self.photo.nil?
		send_tweets unless self.reps.nil? && ( self.sendTweet || self.sendTweet.nil? )
		send_emails
		save_to_fanbridge
	end

	def save_to_fanbridge
		params = {}
		params['firstName'] = firstName
		params['lastname'] = lastName
		params['email'] = email
		params['zip'] = zip
		params['twitter_url'] = twitter
		fanbridge_send params
		friends.split(",").each{ |e| fanbridge_send( {'email' => e } ) } unless self.friends.nil?
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


		# could auto-tag... https://graph.facebook.com/search?q=zuck@fb.com&type=user&access_token=+token
		token = RestClient.get 'https://graph.facebook.com/oauth/access_token?client_id='+ENV['FACEBOOK']+'&client_secret='+ENV['FACEBOOK_SECRET']+'&grant_type=fb_exchange_token&fb_exchange_token='+ENV['TOKEN']
		token.gsub!('access_token=','')
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

		self.update_attributes( :photo_path => facebook_photo.source )
		self.facebook_photo_link = facebook_photo.link
	end

	def send_tweets
		#  Use SoundOff's find reps method to find reps with the bioguides
		reps = JSON::parse( RestClient.get('http://www.soundoffatcongress.org/find_reps?bio='+self.reps ) )
		reps.each{ |rep| enqueue_tweet( rep ) }
	end

	def send_emails
		puts self.facebook_photo_link
	end

	#  Helper functions
	def enqueue_tweet rep
		user = twitter.nil? || twitter.empty? ? "#{firstName}" : '@'+twitter

		if rep['chamber'] == 'house'
			message = "@#{rep['twitter_screen_name']}, #{user} from your district asks you to cosponsor Safe Schools laws (HR1625/HR1199) #SoundOff"
		else
			message = "@#{rep['twitter_screen_name']}, #{user} from your district asks you to cosponsor Safe Schools laws (S403/S1088) #SoundOff"
		end

		self.statuses.new({ :message => message, :target => rep['twitter_screen_name'] }).save

	end

	def fanbridge_send params={}
		form = 'http://www.fanbridge.com/signup/fansignup_form.php?userid=177433'
		params[:welcome_message] = false
		RestClient.post( form, params ){|response, request, result| response }
	end


end
