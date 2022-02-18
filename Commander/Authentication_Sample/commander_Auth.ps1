$BaseURL = "https://localhost:8443"
$user = ""
$pass = ""
					
#Get a token   
Write-host "Requesting a new token"
$TokenBody = "{
      ""username"": ""$user"",
      ""password"": ""$pass""
      }"
					 
$Tokenendpoint = "/rest/v3/tokens"
$TokenpostURL = $BaseURL + $Tokenendpoint
$Tokenresult = Invoke-RestMethod $TokenpostURL -Method POST -Body $TokenBody -ContentType 'application/json' -SkipCertificateCheck
    IF ($Tokenresult) {
        $authToken = $Tokenresult.token
        $headers = @{Authorization = ("Bearer $authToken") }
        Write-host "Token Acquired"
    }
    else {
        Write-host "Failed to aquire token for $user"
    }
					
#Refresh JWT Token 
    $refreshURL = $BaseURL+"/rest/v3/tokens/refresh"
    $refreshBody = "{ ""token"": ""$authToken""}"
    $refreshResult = Invoke-RestMethod -Method POST $refreshURL -Body $refreshBody -ContentType 'application/json' -SkipCertificateCheck
    $authToken = $refreshResult.token
    $headers = @{"Authorization" = "Bearer $authToken" }	