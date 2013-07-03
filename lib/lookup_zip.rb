require 'rest-client'
require 'json'

def matchZip zip
	lat = zip[2]
	long = zip[3]
	query = "http://congress.api.sunlightfoundation.com/legislators/locate?apikey=8fb5671bbea849e0b8f34d622a93b05a&latitude=#{lat}&longitude=#{long}"
	response = JSON::parse( RestClient.get query )
	begin
		bioguide = response['results'].find{ |f| f['chamber'] == 'house' }['bioguide_id']
		f = File.open('found_zips.txt','a')
		f.write( [zip[0], zip[1], bioguide].join("\t")+"\n" )
		f.close
		puts "matched #{zip[0]} to #{bioguide}"
	rescue
		puts "could not find #{zip[0] }"
	end
end

def go
	zips = File.open('missing_zips.txt').read
	zips = zips.split("\r").map{ |z| z.split("\t") }
	zips.shift
	zips.each{ |zip| matchZip zip }
end