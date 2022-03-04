<#
Connects to Commander and Syncs all Terraform accounts.
#>

$$BaseURL = "#{inputVariable['BaseURL']}"
$User = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value; #Credential
$Pass = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$BypassCert = "#{inputVariable['bypass_Cert']}" 
$WaitforSync = "#{inputVariable['waitforSync']}" #seconds

#Check All Variables Presenta
if (!($BaseURL ) -or !($WaitforSync) -or !($user) -or !($pass) -or !($BypassCert)) {
        Write-error "Please provide all required input variables to execute this workflow"
        Exit 1} 

#$DebugPreference="Continue"
$ErrorActionPreference = "Stop"

#Bypass unsigned SSL for Localhost
if ($BypassCert -eq "yes") {
    Write-host "- Ignoring invalid Certificate" -ForegroundColor Green
    add-type @"
   using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::Expect100Continue = $true
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

#Get a token   
    Write-host "Requesting a new token"
    $TokenBody = "{
        ""username"": ""$user"",
        ""password"": ""$pass""
        }"
                        
    $Tokenendpoint = "/rest/v3/tokens"
    $TokenpostURL = $BaseURL + $Tokenendpoint
    $Tokenresult = Invoke-RestMethod $TokenpostURL -Method POST -Body $TokenBody -ContentType 'application/json' 
        IF ($Tokenresult) {
            $authToken = $Tokenresult.token
            $headers = @{Authorization = ("Bearer $authToken") }
            Write-host "Token Acquired"
        }
        else {
            Write-host "Failed to aquire token for $user"
        }
 
#Get TF Accounts
    $AccountsEP = "/rest/v3/terraform-accounts"
    $Accounturl = $BaseURL+$AccountsEP    
    $Accountresult = Invoke-RestMethod $Accounturl -Method GET -header $headers -ContentType 'application/json' 
        IF ($Accountresult.items.count -gt 0) {
            $accounts = $Accountresult.items
            $Accounts | ForEach-Object {
            $id = $TFaName = $SyncResult = $SyncEP = $null
            $ID = $_.id
            $TFaName = $_.name
            $SyncEP = $BaseURL+"/rest/v3/terraform-accounts/$id/synchronize"  
            #Refresh JWT Token 
                $refreshURL = $BaseURL + "/rest/v3/tokens/refresh"
                $refreshBody = "{ ""token"": ""$authToken""}"
                $refreshResult = Invoke-RestMethod -Method POST $refreshURL -Body $refreshBody -ContentType 'application/json' 
                $authToken = $refreshResult.token
                $headers = @{"Authorization" = "Bearer $authToken" }
            $SyncResult = Invoke-WebRequest $SyncEP -Method POST -header $headers -ContentType 'application/json'   
                if($SyncResult.StatusCode -eq 200 -or $SyncResult.StatusCode -eq 202 ){
                    Write-host "Syncronization of Terraform Account : $TFaName - $id , has started." `n
                }
                else{
                    Write-host "Syncronization Task of Terraform Account : $TFaName - $id was not started as expected." `n
                }
           }
        }
        else {
            Write-host "No accounts were returned, Nothing to Sync"
            Exit 0
        }   
#wait a few seconds for Syncs to complete        
Start-sleep $WaitforSync 
