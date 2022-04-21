from ast import For
from operator import eq
import requests
import json			

#Provinces
provinceurl = "http://geogratis.gc.ca/services/geoname/en/codes/province"
headers = {"Accept" : "application/json"}
result = requests.get(provinceurl, headers=headers  , verify=False) 
resultdata = result.text
JsonData = json.loads(resultdata)
definitions = JsonData['definitions']
provinces = []
for item in definitions:
  provinces.append(item['description'])
data = json.dumps(provinces)
print(data)