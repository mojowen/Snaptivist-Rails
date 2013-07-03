task :send_tweets => :environment do
	Status.all( :conditions => { :sent => false }, :limit => 10, :order => 'RANDOM()' ).each(&:send_tweet)
end