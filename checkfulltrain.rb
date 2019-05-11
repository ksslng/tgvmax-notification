require 'csv'

def csv_to_array(string)
	string = string.chomp
	string = string.gsub(';', ',')
    csv = CSV::parse(string)
    fields = csv.shift
    fields = fields.map {|f| f.downcase.gsub(" ", "_")}
    csv.collect { |record| Hash[*fields.zip(record).flatten ] } 
end

def trainline_query(requested_trip)
	departure_station = requested_trip[:departure_station]
	arrival_station = requested_trip[:arrival_station]
	from_date = requested_trip[:from_date]
	to_date = requested_trip[:to_date]

	query = "python3 main.py \'#{departure_station}\' \'#{arrival_station}\' \'#{from_date}\' \'#{to_date}\'"
	result = `#{query}`
end

def tgvmax_checker(trips)
	trips.each do |trip|
		return trip if trip["price"] == "0"
	end
	return false
end

def search_loop(trips_to_search) #work in progress
	while(!trips_to_search.empty?) do
		trips_to_search.each do |trip_to_search|
			query_result = trainline_query(trip_to_search)
			search_results = csv_to_array(query_result)
			if (free_trip = tgvmax_checker(search_results))
				#Notification action
				puts "Le train suivant est disponible : "
				puts free_trip
				#puts "delete index #{index}"
				trips_to_search.delete(trip_to_search)
				#Delete trip_to_search from array
			else
				puts "Aucun train dispo de #{trip_to_search[:departure_station]} a #{trip_to_search[:arrival_station]} entre le #{trip_to_search[:from_date]} et #{trip_to_search[:to_date]}"
			end
		end
		if (!trips_to_search.empty?)
			puts "Prochaine recherche dans une heure"
			sleep(10)
			#sleep(3600)
		else
			puts "Toutes les recherches ont permis de trouver des TGVMAX disponible"
		end
	end
end

trips_to_search = []
trip1 = {:departure_station => "Toulouse" , :arrival_station => "Bordeaux", :from_date => "14/05/2019 08:00", :to_date => "14/05/2019 21:00"}
trips_to_search.push(trip1)
trip2 = {:departure_station => ARGV[0] , :arrival_station => ARGV[1], :from_date => ARGV[2], :to_date => ARGV[3]}
trips_to_search.push(trip2)

search_loop(trips_to_search)
