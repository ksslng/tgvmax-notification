require 'csv'
require 'json'
require 'net/http'
require 'dotenv/load'
require 'shorturl'
require 'date'
require 'time'

def save_array_to_json_file(array, json_file)
	file = File.open(json_file, "w")
	file.write(array.to_json)
	file.close
end

def trainline_date_generator(departure_date)
	temp_time = Time.parse(departure_date)
	temp_time.strftime("%Y-%m-%d-%H:%M")
end

def url_generator(departure_station, arrival_station, departure_date)
	tl_departure_date = trainline_date_generator(departure_date)
	url = "https://www.trainline.fr/search/#{departure_station}/#{arrival_station}/#{tl_departure_date}"
	ShortURL.shorten(url)
end

def send_email_ifttt(departure_station, arrival_station, departure_date)
	tl_departure_date = trainline_date_generator(departure_date)
	response = Net::HTTP.post_form(
		URI('https://maker.ifttt.com/trigger/place_available/with/key/' + ENV['IFTTT']),
		'value1' => departure_station,
		'value2' => arrival_station,
		'value3' => tl_departure_date,
	)

	if response.code != '200'
		puts 'Not OK (non-200 status code received)'
	end
end

def read_json_file(json_file)
	file = File.read(json_file)
	data = JSON.parse(file)
end

def add_trip_to_list(trips_to_search, departure_station, arrival_station, from_date, to_date)
	newtrip = {"departure_station" => departure_station , "arrival_station" => arrival_station, "from_date" => from_date, "to_date" => to_date}
	trips_to_search.push(newtrip)
	save_array_to_json_file(trips_to_search, @json_file_path)
	abort("Le trajet a ete ajoute")
end

def remove_trip_from_list(trips_to_search, departure_station, arrival_station, from_date, to_date)
	trip_to_delete = {"departure_station" => departure_station , "arrival_station" => arrival_station, "from_date" => from_date, "to_date" => to_date}
	if trips_to_search.delete(trip_to_delete)
		save_array_to_json_file(trips_to_search, @json_file_path)
		abort("Le trajet a ete supprime")
	else
		abort("erreur lors de la suppression")
	end
end

def csv_to_array(string)
	string = string.chomp
	string = string.gsub(';', ',')
    csv = CSV::parse(string)
    fields = csv.shift
    fields = fields.map {|f| f.downcase.gsub(" ", "_")}
    csv.collect { |record| Hash[*fields.zip(record).flatten ] } 
end

def trainline_query(requested_trip)
	departure_station = requested_trip["departure_station"]
	arrival_station = requested_trip["arrival_station"]
	from_date = requested_trip["from_date"]
	to_date = requested_trip["to_date"]

	query = "python3 main.py \'#{departure_station}\' \'#{arrival_station}\' \'#{from_date}\' \'#{to_date}\'"
	`#{query}`
end

def tgvmax_checker(trips)
	trips.each do |trip|
		return trip if trip["price"] == "0"
	end
	return false
end

def clean_if_outdated(trips_to_search, trip_to_search)
	if Date.today > Date.parse(trip_to_search['from_date'])
		puts "Trajet supprimme car deja passe : " + trip_to_search.to_s
		trips_to_search.delete(trip_to_search)
		save_array_to_json_file(trips_to_search, @json_file_path)
	end
end

def search_loop(trips_to_search)
	while(!trips_to_search.empty?) do
		trips_to_search.each do |trip_to_search|
			puts Time.now.strftime("%H:%M") + " Recherche d'un train de #{trip_to_search["departure_station"]} a #{trip_to_search["arrival_station"]} entre le #{trip_to_search["from_date"]} et #{trip_to_search["to_date"]}"
			query_result = trainline_query(trip_to_search)
			if (query_result.nil?)
				puts Time.now.strftime("%H:%M") +  " Response from Trainline is nil"
				next
			end
			search_results = csv_to_array(query_result)
			if (free_trip = tgvmax_checker(search_results))
				puts "Le train suivant est disponible : "
				puts free_trip
				send_email_ifttt(trip_to_search["departure_station"],trip_to_search["arrival_station"], free_trip["departure_date"])
				trips_to_search.delete(trip_to_search)
				save_array_to_json_file(trips_to_search, @json_file_path)
			else
				puts Time.now.strftime("%H:%M") + " Aucun train dispo de #{trip_to_search["departure_station"]} a #{trip_to_search["arrival_station"]} entre le #{trip_to_search["from_date"]} et #{trip_to_search["to_date"]}"
			end
			clean_if_outdated(trips_to_search, trip_to_search)
		end
		if (!trips_to_search.empty?)
			puts Time.now.strftime("%H:%M") + " Prochaine recherche dans une heure\n\n"
			sleep(3600)
		else
			puts "Toutes les recherches ont permis de trouver des TGVMAX disponible"
		end
	end
end

@json_file_path = "trips_to_search.json"
trips_to_search = read_json_file(@json_file_path)
add_trip_to_list(trips_to_search, ARGV[1], ARGV[2], ARGV[3], ARGV[4]) if (ARGV.length == 5 && ARGV[0].downcase == "add")
remove_trip_from_list(trips_to_search, ARGV[1], ARGV[2], ARGV[3], ARGV[4]) if (ARGV.length == 5 && ARGV[0].downcase == "remove")
abort("Aucun trajet dans la liste d'attente. Le programme va quitter") if trips_to_search.empty?
puts "La recherche va commencer"
search_loop(trips_to_search)
