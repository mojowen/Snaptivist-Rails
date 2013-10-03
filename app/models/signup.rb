class Signup < ActiveRecord::Base

  	attr_accessible :firstName, :lastName, :email, :zip, :twitter, :photo_date, :complete,
  		:friends, :reps,
  		:photo_path, :facebook_photo, :source,
		:sendTweet, :event,
		:no_signup, :auth_key

	attr_accessor :sendTweet, :event, :no_signup, :auth_key
	validates_presence_of :email, :firstName, :zip

  	has_many :statuses
	after_validation :set_source
	before_save :handle_webform

	def set_source
		unless event.index('auto-select event').nil?
			events = {
				'2013-07-06' => "7/6/2013\tToronto,  ONT\tDownsview",
				'2013-07-07' => "7/7/2013\tOttawa,  ONT\tBlues Festival",
				'2013-07-09' => "7/9/2013\tCleveland,  OH\tJacobs",
				"2013-07-10" => "7/10/2013\tChicago,  IL\tTaste of Chicago",
				"2013-07-12" => "7/12/2013\tCincinnati,  OH\tBunbury Festival",
				"2013-07-13" => "7/13/2013\tCanandaigua, NY\tConstellation Brands Marvin Sands",
				"2013-07-14" => "7/14/2013\tColumbus,  OH",
				"2013-07-16" => "7/16/2013\tDetroit,  MI\tMeadowbrook",
				"2013-07-18" => "7/18/2013\tPittsburgh,  PA\tStage AE",
				"2013-07-19" => "7/19/2013\tPhiladelphia,  PA\tMann Center",
				"2013-07-20" => "7/20/2013\tWashington,  DC\tMerriweather",
				"2013-07-22" => "7/22/2013\tNYC, NY\tPier 27",
				"2013-07-23" => "7/23/2013\tNYC, NY\tPier 27",
				"2013-08-21" => "8/21/2013\tDenver,  CO\tRed Rocks TBA",
				"2013-08-22" => "8/22/2013\tDenver,  CO\tRed Rocks",
				"2013-08-23" => "8/23/2013\tSalt Lake City,  UT\tGreat Salt Air",
				"2013-08-27" => "8/27/2013\tStateline,  NV\tLake Tahoe Harvey's Outdoor Arena",
				"2013-08-28" => "8/28/2013\tBoise,  ID\tBotanical Gardens",
				"2013-08-29" => "8/29/2013\tPortland,  OR\tEdgefield",
				"2013-08-31" => "8/31/2013\tVancouver,  BC",
				"2013-09-01" => "9/1/2013\tSeattle,  WA\tBumbershoot",
				"2013-09-03" => "9/3/2013\tLA, CA\tGreek # 2",
				"2013-09-04" => "9/4/2013\tLos Angeles,  CA\tGreek",
				"2013-09-06" => "9/6/2013\tBerkeley,  CA\tGreek",
				"2013-09-07" => "9/7/2013\tSanta Barbara,  CA\tSB Bowl",
				"2013-09-08" => "9/8/2013\tBerkeley,  CA\tGreek # 2",
				"2013-09-10" => "9/10/2013\tPhoenix,  AZ",
				"2013-09-12" => "9/12/2013\tDallas,  TX\tGexa Energy Pavill",
				"2013-09-14" => "9/14/2013\tSt. Augustine,  FL\tMumford Festival",
				"2013-09-16" => "9/16/2013\tTuscaloosa,  AL\tAmphitheater",
				"2013-09-18" => "9/18/2013\tBoca Raton,  Fl\tSunset Cove",
				"2013-09-19" => "9/19/2013\tOrlando,  FL\tUCF Arena",
				"2013-09-20" => "9/20/2013\tLas Vegas,  NV\tI heart Radio",
				"2013-09-22" => "9/22/2013\tNashville,  TN\tFontenell",
				"2013-09-24" => "9/24/2013\tCharleston,  SC\tTennis Center",
				"2013-09-25" => "9/25/2013\tRaliegh,  NC",
				"2013-09-26" => "9/26/2013\tCharlottesville,  VA\tnTelos Wireless Pavilion",
				"2013-09-28" => "9/28/2013\tBridgeport,  CT",
				"2013-10-04" => "10/4/2013\tAustin,  TX\tACL Festival",
				"2013-10-05" => "10/5/2013\tNew Orleans,  LA",
				"2013-10-06" => "10/6/2013\tHouston,  TX",
				"2013-10-08" => "10/8/2013\tAtlanta,  GA",
				"2013-10-09" => "10/9/2013\tStarkville,  MS",
				"2013-10-11" => "10/11/2013\tAustin,  TX\tACL Festival",
				"2013-10-13" => "10/13/2013\tMexico City,  MEX\tCorona Festival"
			}
			self.event = events[ photo_date.to_s ]
			errors[:event] << 'Could not find event based on that photo date' if self.event.nil?
		end
		self.source = event.gsub("\t"," ").strip if event && ! complete
	end
	def handle_webform
		if (self.source || '' ).downcase == 'webform'
			save_to_fanbridge
			self.complete = true
			self.photo_date = DateTime.now
		end
	end

	def match_or_save
		return true if ! self.no_signup.nil? || self.auth_key != ENV['ALLY_KEY']
		match_back = Signup.where( :firstName => self.firstName, :lastName => self.lastName, :email => email, :zip => self.zip, :photo_date => self.photo_date ).first
		unless match_back
			return self.save
		else
			match_back.touch
			return true
		end
	end

	after_save :send_sync
	def send_sync
		Thread.new{ sync } unless complete
	end
	def sync add_event=nil
		unless add_event.nil?
			self.event = add_event
			source = event.gsub("\t",' ')
		end

		if photo_path
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
	before_destroy :remove_aws, :delete_statuses
	def remove_aws
		AWS::S3::S3Object.delete( file_name, 'tac' ) if photo_path
	end
	def delete_statuses
		statuses.each(&:delete)
	end


	def send_photo_to_facebook

		event_deets = event.split("\t").map{|s| s.strip }.reject{ |s| s.nil? || s.empty? }

		if event_deets.length == 3
			city = event_deets[1].split(', ')[0]
			album_title = "#{event_deets[2]}: #{event_deets[0]} in #{city}"
			album_description = "FUN. was in #{city} to play #{event_deets[2]}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
			photo_description = "Photo from FUN. at #{event_deets[2]} in #{city}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
		else
			city = event_deets[1].split(', ')[0]
			album_title = "#{event_deets[0]} in #{city}"
			album_description = "FUN. was in #{city}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
			photo_description = "Photo from FUN. in #{city}. Meet some of the allies that stopped by The Ally Coalition Equality Village! Please tag yourself and your friends"
		end

		fb_init

		album = fb_album album_title, album_description

		uploaded_photo = album.photo!( :url => photo_path, :message => photo_description, :token => @token )

		self.facebook_photo = "https://www.facebook.com/photo.php?fbid=#{uploaded_photo.identifier}"

		if does_send_tweets
			send_tweets
		else
			send_emails
		end
	end

	def does_send_tweets
		return ! self.reps.nil? && ! self.reps.empty? && ( self.sendTweet.to_i != 0 rescue false)
	end

	def send_tweets skip_emails=false
		#  Use SoundOff's find reps method to find reps with the bioguides
		if self.reps.class == String
			self.reps = JSON::parse( RestClient.get('http://www.soundoffatcongress.org/find_reps?bio='+self.reps ) )
		end
		reps.each{ |rep| enqueue_tweet( rep ) }
		send_emails unless skip_emails
	end

	def send_emails
		event_deets = event.split("\t").map{|s| s.strip }.reject{ |s| s.nil? || s.empty? }
		event_name = event_deets[1].split(', ').first

		if (self.zip.length != 5 rescue true ) && !self.facebook_photo.nil?
			WelcomeMailer.canadian( self.email, event_name, self.facebook_photo).deliver

			unless friends.nil?
				(friends || '').split(',').each do |friend|
					WelcomeMailer.canadian( friend, event_name, self.facebook_photo).deliver
				end
			end
		else
			if self.zip.length == 5 && self.sendTweet && self.reps.class == Array
				WelcomeMailer.us_tweet( self, event_name, self.facebook_photo ).deliver
			else
				WelcomeMailer.us_no_tweet( self, event_name, self.facebook_photo ).deliver
			end

			unless friends.nil?
				( friends || '').split(',').each do |friend|
					WelcomeMailer.us_no_tweet( friend, event_name, self.facebook_photo ).deliver
				end
			end
		end

	end
	def save_to_fanbridge


		signup = {}
		signup['firstname'] = firstName
		signup['email'] = email
		signup['lastname'] = lastName unless lastName.nil?
		signup['twitter_url'] = 'http://twitter.com/'+twitter unless twitter.nil?
		signup['zip'] = zip

		fanbridge_send signup

		(friends || '').split(",").each do |e|
			signup = {}
			signup['email'] = email
			fanbridge_send signup
		end
	end


	#  Helper functions
	def enqueue_tweet rep
		user = twitter.nil? || twitter.empty? ? "#{firstName}" : '@'+twitter

		if rep['chamber'] == 'house'
			message = "@#{rep['twitter_screen_name']} #{user} from your district asks you to sponsor Safe Schools HR1652/HR1199 #MostNights #SoundOff"
		else
			message = "@#{rep['twitter_screen_name']} #{user} from your district asks you to sponsor Safe Schools S403/S1088 #MostNights #SoundOff"
		end

		self.statuses.new({ :message => message, :target => rep['twitter_screen_name'] }).save
	end
	def fanbridge_send request

		request['token'] = ENV['FANBRIDGE_TOKEN']

		request['signature'] = Digest::MD5.hexdigest( request.sort_by{|k| k}.map{ |k,v| "#{k}=#{v}"}.join('') + ENV['FANBRIDGE_SECRET'] )

		url = "https://api.fanbridge.com/v3/subscriber/add.json"

		return RestClient.post url, request
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

  	# some methods for deleting photos
  	def fb_me token=nil
  		if ENV['PAGE_ID']
  			@token = token || Rails.cache.read('page_token') || ENV['PAGE_TOKEN']
  			@fb_user = FbGraph::Page.new( ENV['PAGE_ID'], :access_token => @token ).fetch
  		else
			@token = token || Rails.cache.read('TOKEN') || ENV['TOKEN']
  			@fb_user = FbGraph::User.me( @token )
  		end
  	end
  	def fb_init
  		begin
			fb_me
		rescue
			token = RestClient.get('https://graph.facebook.com/oauth/access_token?client_id='+ENV['FACEBOOK']+'&client_secret='+ENV['FACEBOOK_SECRET']+'&grant_type=fb_exchange_token&fb_exchange_token='+ENV['TOKEN']).gsub!('access_token=','')
			if ENV['PAGE_ID']
				page_token = JSON::parse( RestClient.get('https://graph.facebook.com/me/accounts?access_token='+token) )
				token = page_token['data'].find{ |f| f['id'] == ENV['PAGE_ID']}['access_token']
			end
			Rails.cache.write('page_token',token)
			fb_me token
		end
		return @fb_user
	end
	def fb_album album_title, album_description
		album = @fb_user.albums.find{|f| f.name == album_title }
		if ENV['PAGE_ID']
			album = @fb_user.album!( :name => album_title, :message => album_description, :token => @token ) if album.nil?
		else
			privacy = {'value' => 'CUSTOM', 'allow' => '40900695,577932694'}
			album = @fb_user.album!( :name => album_title, :message => album_description, :token => @token, :privacy => privacy ) if album.nil?
		end
		return album
	end
end
