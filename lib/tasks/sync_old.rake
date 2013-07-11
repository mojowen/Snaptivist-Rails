desc "sync old photos"
task :sync_old => [:environment ] do

	events = {
		'2013-07-06' => "7/6/2013\tToronto,  ONT\tDownsview",
		'2013-07-07' => "7/7/2013\tOttawa,  ONT\tBlues Festival",
		'2013-07-09' => "7/9/2013\tCleveland,  OH\tJacobs",
		"2013-07-10" => "7/10/2013/tChicago,  IL/tTaste of Chicago",
		"2013-07-12" => "7/12/2013/tCincinnati,  OH/tBunbury Festival",
		"2013-07-13" => "7/13/2013/tCanandaigua, NY/tConstellation Brands Marvin Sands",
		"2013-07-14" => "7/14/2013/tColumbus,  OH",
		"2013-07-16" => "7/16/2013/tDetroit,  MI/tMeadowbrook",
		"2013-07-18" => "7/18/2013/tPittsburgh,  PA/tStage AE",
		"2013-07-19" => "7/19/2013/tPhiladelphia,  PA/tMann Center",
		"2013-07-20" => "7/20/2013/tWashington,  DC/tMerriweather",
		"2013-07-22" => "7/22/2013/tNYC, NY/tPier 27",
		"2013-07-23" => "7/23/2013/tNYC, NY/tPier 27",
		"2013-08-21" => "8/21/2013/tDenver,  CO/tRed Rocks TBA",
		"2013-08-22" => "8/22/2013/tDenver,  CO/tRed Rocks",
		"2013-08-23" => "8/23/2013/tSalt Lake City,  UT/tGreat Salt Air",
		"2013-08-27" => "8/27/2013/tStateline,  NV/tLake Tahoe Harvey's Outdoor Arena",
		"2013-08-28" => "8/28/2013/tBoise,  ID/tBotanical Gardens",
		"2013-08-29" => "8/29/2013/tPortland,  OR/tEdgefield",
		"2013-08-31" => "8/31/2013/tVancouver,  BC",
		"2013-09-01" => "9/1/2013/tSeattle,  WA/tBumbershoot",
		"2013-09-03" => "9/3/2013/tLA, CA/tGreek # 2",
		"2013-09-04" => "9/4/2013/tLos Angeles,  CA/tGreek",
		"2013-09-06" => "9/6/2013/tBerkeley,  CA/tGreek",
		"2013-09-07" => "9/7/2013/tSanta Barbara,  CA/tSB Bowl",
		"2013-09-08" => "9/8/2013/tBerkeley,  CA/tGreek # 2",
		"2013-09-10" => "9/10/2013/tPhoenix,  AZ",
		"2013-09-12" => "9/12/2013/tDallas,  TX/tGexa Energy Pavill"
	}
	events.each do |k,event|
		batch = Signup.find_all_by_photo_date_and_complete(k,false)
		batch.each do |s|
			begin
				s.sync event
				puts "#{s.firstName} #{s.id} success"
			rescue => e
				puts "#{s.firstName} #{s.id} fail #{e}"
			end
		end
	end
end