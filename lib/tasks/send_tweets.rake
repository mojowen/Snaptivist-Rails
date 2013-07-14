task :send_tweets => :environment do
	if DateTime.now.utc.hour > 11 || DateTime.now.utc.hour < 2
		Status.all( :conditions => { :sent => false }, :limit => 1, :order => 'RANDOM()' ).each do |status|
			puts status.send_tweet
		end
	end
end