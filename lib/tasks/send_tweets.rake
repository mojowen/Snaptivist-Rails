task :send_tweets => :environment do
	if DateTime.now.utc.hour > 11 || DateTime.now.utc.hour < 2
		Status.all( :conditions => { :sent => false }, :limit => 10, :order => 'RANDOM()' ).each do |status|
			puts status.send_tweet
			sleep(45)
		end
	end
end