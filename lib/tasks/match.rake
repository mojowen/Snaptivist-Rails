desc "match non synced photos"
task :remove_photos => [:environment ] do
	require 'RMagick'

	signups = Signup.where('photo_path IS NOT NULL').offset(359).select{ |s| s.photo_date.to_s == '2013-07-09' || s.photo_date.to_s == '2013-07-06' }

	(15 + 48).times{ signups.shift }


	signups.each_with_index do |signup,index|

		image1 = Magick::ImageList.new
		image1.from_blob( open( signup.photo_path.split('?')[0] ).read )
		image1 = image1.resize(600,450)

		date = signup.photo_date.to_s
		matches = Dir.glob('./uploads/'+signup.photo_date.to_s+'*.jpg')

		matches.each do |photo|
			image2 = Magick::ImageList.new
			image2.from_blob( open( photo ).read )
			image2 = image2.resize(600,450)

			if image1.compare_channel( image2, Magick::MeanAbsoluteErrorMetric).last < 0.01
				File.delete(photo)
				puts "Deleted #{photo}"
				break;
			end
		end
		puts "#{index} of #{signups.length}"
	end

end