if ENV['TWITTER']
	Twitter.configure do |config|
	  config.consumer_key = ENV['TWITTER']
	  config.consumer_secret = ENV['TWITTER_SECRET']
	  config.oauth_token = ENV['TWITTER_ACCESS_TOKEN']
	  config.oauth_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
	end
end
