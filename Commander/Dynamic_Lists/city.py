from ast import For
from operator import eq
import requests
import json		

#Set province from previous list
choice = "#{service.settings.dynamicList['Province']}"
#get provices to get ID for selected
headers = {"Accept" : "application/json"}
provinceurl = "http://geogratis.gc.ca/services/geoname/en/codes/province"
result = requests.get(provinceurl, headers=headers  , verify=False) 
resultdata = result.text
JsonData = json.loads(resultdata)
definitions = JsonData['definitions']
parsed_definition = [x for x in definitions if x['description'] == choice]
for province in parsed_definition:
   provinceid = (province['code'])

Cityurl = "http://geogratis.gc.ca/services/geoname/en/geonames?province="+provinceid+"&concise=CITY"
cityresult = requests.get(Cityurl, headers=headers  , verify=False) 
cityresultdata = cityresult.text
cityJdata = json.loads(cityresultdata)
cities = []
for items in cityJdata['items']:
  cities.append(items['name'])
data = json.dumps(cities)  
print(data) 