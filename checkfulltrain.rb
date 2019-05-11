require 'csv'

def csv_to_array(string)
	string = string.chomp
	string = string.gsub(';', ',')
    csv = CSV::parse(string)
    fields = csv.shift
    fields = fields.map {|f| f.downcase.gsub(" ", "_")}
    csv.collect { |record| Hash[*fields.zip(record).flatten ] } 
end

def trainline_query()
	departure_station = ARGV[0]
	arrival_station = ARGV[1]
	from_date = ARGV[2]
	to_date = ARGV[3]

	query = "python3 main.py \'#{departure_station}\' \'#{arrival_station}\' \'#{from_date}\' \'#{to_date}\'"
	result = `#{query}`
end

def tgvmax_checker(trips)
	trips.each do |trip|
		return trip if trip["price"] == "0"
	end
	return false
end

def loop_checker(trips) #work in progress
	free_trip = tgvmax_checker(trips)
	while (!free_trip)
		puts "no free tgvmax trips :("
		sleep(1.hour)
		free_trip = tgvmax_checker(trips)
	end
end

trips_to_search = []
trip1 = {:departure_station => "Toulouse" , :arrival_station => "Bordeaux", :from_date => "14/05/2019 08:00", :to_date => "14/05/2019 21:00"}
trips_to_search.push(trip1)
trip2 = {:departure_station => ARGV[0] , :arrival_station => ARGV[1], :from_date => ARGV[2], :to_date => ARGV[3]}
trips_to_search.push(trip2)


query_result = trainline_query
trips = csv_to_array(query_result)
free_trip = tgvmax_checker(trips)
if free_trip
	puts free_trip
else
	puts "aucun train dispo"
end
