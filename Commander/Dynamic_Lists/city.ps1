<#City selection from pubic endpoints, to follow the province selection script
Takes the output from the previous Dynamic list as "#{service.settings.dynamicList['Province']}"
#>

$headers = @{Accept = "application/json" }	
$Data = Invoke-RestMethod -Method Get -Uri "http://geogratis.gc.ca/services/geoname/en/codes/province" -Headers $headers
$Provinceid = $Data.definitions | Where-Object {$_.description -eq "#{service.settings.dynamicList['Province']}"} | Select-object code -ExpandProperty code
$CityData = Invoke-RestMethod -Method Get -Uri "http://geogratis.gc.ca/services/geoname/en/geonames?province=$Provinceid&concise=CITY" -Headers $headers

$result = @()

if ($CityData.items.Length > 1) {
   $result += $CityData.items |Select -ExpandProperty name 
} else {
   $result = $CityData.items |Select -ExpandProperty name
}

ConvertTo-Json @($result)