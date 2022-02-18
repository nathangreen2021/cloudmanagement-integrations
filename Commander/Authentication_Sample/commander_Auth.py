import requests
					
baseurl = "https://localhost:8443"
username = ""
password = ""
					
#Get a token
tokenurl = "/rest/v3/tokens"
tokenposturl = baseurl+tokenurl
print( 'Token Get URL: ' + tokenposturl)
tokenbody = { "username": username, "password": password}
tokenresult = requests.post(tokenposturl, json=tokenbody , verify=False) 
tokenresult = tokenresult.json()
authtoken = tokenresult["token"]
print ('Token aquired: ' + authtoken)
					
#Refresh an existing token
tokenrefreshurl = "/rest/v3/tokens/refresh"
tokenposturl = baseurl+tokenrefreshurl
tokenrefreshbody = { "token": authtoken}
tokenrefreshresult = requests.post(tokenposturl, json=tokenrefreshbody , verify=False) 
tokenrefreshresult = tokenrefreshresult.json()
authtoken = tokenrefreshresult["token"]
print('Refreshed Token Aquired:' + authtoken)	