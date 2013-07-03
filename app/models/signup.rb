class Signup < ActiveRecord::Base
  	attr_accessible :firstName, :lastName, :email, :zip, :twitter, :friends, :reps, :photo_date, :photo_path, :photo, :sendTweet, :event, :facebook_photo_link
	attr_accessor :photo, :sendTweet, :event, :facebook_photo_link
  	before_save :save_photo
  	after_save :sync

  	has_many :statuses

  	def tmp_file_name
		[firstName,lastName,photo_date].join('_')+'.png'
  	end
  	def tmp_file_path
		file = "tmp/#{tmp_file_name}"
  	end
  	def save_photo
  		unless photo.nil?
  			File.delete(tmp_file_path) if File.exists?( tmp_file_path )

	  		File.open( tmp_file_path, 'wb') do |f|
	  			f.write( photo.read )
	  		end
	  		self.photo_path = '/'+tmp_file_name
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
		# could auto-tag... https://graph.facebook.com/search?q=zuck@fb.com&type=user&access_token=+token
		# token = RestClient.get 'https://graph.facebook.com/oauth/access_token?client_id='+ENV['FACEBOOK']+'&client_secret='+ENV['FACEBOOK_SECRET']+'&grant_type=fb_exchange_token&fb_exchange_token='+ENV['TOKEN']
		# page_token = 'https://graph.facebook.com/me/accounts?access_token='+token

		event = 'Ally Coalition Test Albumn'

		privacy = {'value' => 'CUSTOM', 'allow' => '40900695,577932694'}
		token = ENV['TOKEN']
		me = FbGraph::User.me( ENV['TOKEN'] )
		album = me.albums.find{|f| f.name == event }
		album = me.album!( :name => event, :privacy => privacy ) if album.nil?

		# token = ENV['PAGE_TOKEN']
		# me = FbGraph::Page.new( ENV['PAGE_ID'], :access_token => token ).fetch
		# album = me.albums.find{|f| f.name == event }
		# album = me.album!( :name => event ) if album.nil?

		begin
			album.photo!( :source => File.open( self.tmp_file_path ), :message => "#{firstName} #{lastName} at #{event}", :token => token )
		rescue
		end

		photo = album.photos.find{ |fb_photo| fb_photo.name == "#{firstName} #{lastName} at #{event}" }

		self.update_attributes( :photo_path => photo.source )
		self.facebook_photo_link = photo.link
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
