# -*- coding: utf-8 -*-
# Code from Tducret (https://ww.tducret.com/) that parse trainline in CSV 
# More informations on his project here : https://github.com/tducret/trainline-python

import trainline
import sys
import os
from dotenv import load_dotenv
load_dotenv()

if len(sys.argv) != 5:
    sys.exit("usage: python3 main.py departure_station arrival_station from_date to_date\nexemple : python3 main.py Paris Nice '10/05/2019 08:00' '10/05/2019 21:00'")

User = trainline.Passenger(birthdate=os.getenv("BIRTHDATE"))
User.add_special_card(trainline.TGVMAX, os.getenv("TGVMAX"))

results = trainline.search(
	passengers=[User],
	departure_station=sys.argv[1],
	arrival_station=sys.argv[2],
	from_date=sys.argv[3],
	to_date=sys.argv[4])


print(results.csv())
