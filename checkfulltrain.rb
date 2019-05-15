require 'csv'
require 'json'
require 'net/http'
require 'dotenv/load'
require 'telerivet'

def save_array_to_json_file(array, json_file)
	file = File.open(json_file, "w")
	file.write(array.to_json)
	file.close
end

def send_sms_telerivet(departure_station, arrival_station, departure_date)
	tr = Telerivet::API.new(ENV['TELERIVET_API_KEY'])
	project = tr.init_project_by_id(ENV['TELERIVET_PROJECT_ID'])

	sent_msg = project.send_message({
	    'content' => "TGVMAX : Un trajet a été trouvé pour le trajet #{departure_station} - #{arrival_station}. Le train partira à #{departure_date}",
		'to_number' => ENV['SMS_RECEIVER_NUMBER']
	})
end

def send_email_ifttt(departure_station, arrival_station, departure_date)
	response = Net::HTTP.post_form(
		URI('https://maker.ifttt.com/trigger/tgvmax/with/key/' + ENV['IFTTT']),
		'value1' => departure_station,
		'value2' => arrival_station,
		'value3' => departure_date,
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

def search_loop(trips_to_search)
	while(!trips_to_search.empty?) do
		trips_to_search.each do |trip_to_search|
				puts "Recherche d'un train de #{trip_to_search["departure_station"]} a #{trip_to_search["arrival_station"]} entre le #{trip_to_search["from_date"]} et #{trip_to_search["to_date"]}"
			query_result = trainline_query(trip_to_search)
			search_results = csv_to_array(query_result)
			if (free_trip = tgvmax_checker(search_results))
				puts "Le train suivant est disponible : "
				puts free_trip
				send_email_ifttt(trip_to_search["departure_station"],trip_to_search["arrival_station"], free_trip["departure_date"])
				send_sms_telerivet(trip_to_search["departure_station"],trip_to_search["arrival_station"], free_trip["departure_date"])
				trips_to_search.delete(trip_to_search)
				save_array_to_json_file(trips_to_search, @json_file_path)
			else
				puts "Aucun train dispo de #{trip_to_search["departure_station"]} a #{trip_to_search["arrival_station"]} entre le #{trip_to_search["from_date"]} et #{trip_to_search["to_date"]}"
			end
		end
		if (!trips_to_search.empty?)
			puts "\nProchaine recherche dans une heure\n"
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
