#Province from pubic endpoints, to be followed by the City Selection

$headers = @{Accept = "application/json" }
$Data = Invoke-RestMethod -Method Get -Uri "http://geogratis.gc.ca/services/geoname/en/codes/province" -Headers $headers
ConvertTo-Json @(($Data.definitions) | Select -ExpandProperty description)