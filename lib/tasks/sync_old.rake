desc "sync old photos"
task :sync_old => [:environment ] do

	events = {
		'2013-07-06' => "7/6/2013\tToronto,  ONT\tDownsview",
		'2013-07-07' => "7/7/2013\tOttawa,  ONT\tBlues Festival",
		'2013-07-09' => "7/9/2013\tCleveland,  OH\tJacobs"
	}
	events.each do |k,event|
		batch = Signup.find_all_by_photo_date_and_complete(k,false)
		batch.each do |s|
			begin
				s.event = event
				s.source = s.event.gsub("\t"," ")
				s.sync
				puts "#{s.firstName} #{s.id} success"
			rescue
				puts "#{s.firstName} #{s.id} fail"
			end
		end
	end
end