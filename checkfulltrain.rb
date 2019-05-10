require 'csv'

def csv_to_array(string)
	string = string.chomp
	string = string.gsub(';', ',')
    csv = CSV::parse(string)
    fields = csv.shift
    fields = fields.map {|f| f.downcase.gsub(" ", "_")}
    csv.collect { |record| Hash[*fields.zip(record).flatten ] } 
end

def trainline_query
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
	return NULL
end

query_result = trainline_query
trips = csv_to_array(query_result)
free_trip = tgvmax_checker(trips)
puts free_trip unless free_trip.nil?

