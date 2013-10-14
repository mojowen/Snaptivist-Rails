task :fix_tweets => :environment do
	Status.fix_old_tweets
end