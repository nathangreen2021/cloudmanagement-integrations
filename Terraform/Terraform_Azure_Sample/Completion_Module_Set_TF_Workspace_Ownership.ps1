<#
Connects to Commander and sets ownership of a workspace based on the Requester and their Organization 
#>

$BaseURL = "#{inputVariable['BaseURL']}"
$User = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value; #Credential
$Pass = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$BypassCert = "#{inputVariable['bypass_Cert']}" 
$WaitforSync = "#{inputVariable['waitforSync']}" #seconds
$Owner = "#{request.requester.userId}"
$Ownerprimary = "false"   # $true:$false
$OwneritContact = "false"   # $true:$false
$Organization = "#{request.requester.organization.name}"
$workspace = "#{request.id}"

 #Check All Variables Presenta
if (!($BaseURL ) -or !($WaitforSync) -or !($user) -or !($pass) -or !($BypassCert) ) {
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
 
#Get TF Workspace
    $wspEP = "/rest/v3/terraform-workspaces?filter=name -eq $Workspace"
    $wspurl = $BaseURL+$wspEP  
    $wspresult = Invoke-RestMethod $wspurl -Method GET -header $headers -ContentType 'application/json' 
    $wspcount = $wspresult.items.count
        IF ($wspcount -eq 1) {
            $id = $TFaName = $SyncResult = $SyncEP = $null 
            $Wspid = $wspresult.items.id
            #Refresh JWT Token 
                $refreshURL = $BaseURL + "/rest/v3/tokens/refresh"
                $refreshBody = "{ ""token"": ""$authToken""}"
                $refreshResult = Invoke-RestMethod -Method POST $refreshURL -Body $refreshBody -ContentType 'application/json' 
                $authToken = $refreshResult.token
                $headers = @{"Authorization" = "Bearer $authToken" }
            if($organization){
                $SetwspOrg = $BaseURL+"/rest/v3/terraform-workspaces/$Wspid/organization"  
                $OrgJson = @{ name = $($Organization)} | ConvertTo-Json
                $wsporgresult = Invoke-WebRequest $SetwspOrg -Method PUT -header $headers -body $OrgJson -ContentType 'application/json'              
            }
            if($Owner){
                $SetwspOwner = $BaseURL+"/rest/v3/terraform-workspaces/$Wspid/owners"  
                $OwnerJson = @{ 
                    name = $($owner) 
                    is_primary = $($Ownerprimary)  
                    is_it_contact = $($OwneritContact) } | ConvertTo-Json
                $wsporgresult = Invoke-WebRequest $SetwspOwner -Method POST -header $headers -body $OwnerJson -ContentType 'application/json'              
            }
        }
        elseif($wspcount -gt 1){
            Write-Error "More than one Workspace was returned.. Please contact your Administrator"
            Exit 1
        }
        else {
            Write-Error "No Workspaces were returned, Please contact your Administrator"
            Exit 1
        }   
#wait a few seconds for Syncs to complete        
Start-sleep $WaitforSync 
