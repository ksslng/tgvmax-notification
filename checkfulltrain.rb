require 'mechanize'
require 'dotenv/load'
def login()
	login = ENV['TRAINLINE_LOGIN']
	password = ENV['TRAINLINE_PASSWORD']
	@mechanize.get('https://www.trainline.fr/signin') do |page|
		page.forms.first do |f|
			f.email = login
			f.password = password
			submit.first.click
		end
	end
	puts "User is now logged in" if @verbose == true
end

if (ARGV[0] && ARGV[1] && ARGV[2])
	@mechanize = Mechanize.new
	origin_city = ARGV[0]
	destination_city = ARGV[1]
	date_departure = ARGV[2]
	@verbose = true if ARGV[3] == "VERBOSE"
	booked = false
	base_url = "https://www.trainline.fr/search/"
	search_url = base_url + origin_city + "/" + destination_city + "/" + date_departure
	puts search_url
	login()
else
	puts "usage : ruby checkfulltrain.rb 'origin city' 'destination city' 'date departure'"
end
