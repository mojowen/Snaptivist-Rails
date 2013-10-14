task :fix_tweets => :environment do
	Status.fix_tweets
end