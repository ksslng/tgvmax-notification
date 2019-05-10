# -*- coding: utf-8 -*-
import trainline
import sys

if len(sys.argv) != 5:
    sys.exit("usage: python3 main.py departure_station arrival_station from_date to_date\nexemple : python3 main.py Paris Nice '10/05/2019 08:00' '10/05/2019 21:00'")

Yann = trainline.Passenger(birthdate="04/07/1994")
Yann.add_special_card(trainline.TGVMAX, 'TGVMAXKEY')

results = trainline.search(
	passengers=[Yann],
	departure_station=sys.argv[1],
	arrival_station=sys.argv[2],
	from_date=sys.argv[3],
	to_date=sys.argv[4])


print(results.csv())
