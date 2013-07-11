task :send_tweets => :environment do
	if DateTime.now.utc.hour > 11 || DateTime.now.utc.hour < 2
		Status.all( :conditions => { :sent => false }, :limit => 10, :order => 'RANDOM()' ).each(&:send_tweet)
	end
end