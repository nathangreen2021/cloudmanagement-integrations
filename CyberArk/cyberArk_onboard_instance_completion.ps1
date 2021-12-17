<# 
CyberArk instance Account onboarding, specifies credentials to be changed by CyberArk
The $Address variable can be change to IP address if required instead of DNS
#> 

#Commander Base Configuration
$BaseURL = "#{inputVariable['commander_url']}"
$Commanderuser = (Get-Item Env:COMMANDER_CREDENTIALS_USERNAME).value;
$Commanderpass = (Get-Item Env:COMMANDER_CREDENTIALS_PASSWORD).value;

#Image Credential from credential library
$imageCredName = "#{inputVariable['image_credential']}"

#CyberArk Base Configuration
$Instance = "#{inputVariable['cyberark_instance']}"
$UserName = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME).value;
$Password = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value; 
$AuthType = "#{inputVariable['cyberark_authtype']}"

#Cyberark New Account registration
$address = "#{target.ipAddressPrivate}"
$SafeName = "#{inputVariable['safe_name']}"
$PlatformID = "#{inputVariable['platform_id']}"
 
# {Yes:No} to bypass unsigned cert on the cyberark server. 
$BypassCert = "Yes" 

##########################################################################################
if(!($Instance) -or !($UserName)-or !($AuthType) -or !($Password)  -or !($imageCredName)){
        Write-error "Please provide the required information for Cyberark"
        Exit 1
        }

if(!($BaseURL) -or !($Commanderuser) -or !($Commanderpass) -or !($BypassCert)){
        Write-error "Please provide Commander information"
        Exit 1
        } 

if(!($SafeName) -or !($PlatformID) -or !($address)){
        Write-error "Please provide Cyberark account registration information"
        Exit 1
        } 


 #ignore Commander unsigned Certificate
if ($BypassCert -eq "Yes"){
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
}

#Get Commander Auth Token
    $Token = $null
    $TokenEndpoint = "/rest/v3/tokens"
    $TokenURL = $BaseURL+$TokenEndpoint
    $TokenBody = "{
                ""username"": ""$Commanderuser"",
                ""password"": ""$Commanderpass"" 
                }"
    $TokenResult = Invoke-RestMethod -Method POST $TokenURL -Body $TokenBody -ContentType 'application/json'
    $Token = $TokenResult.token
    $AuthHeader = @{"Authorization"= "Bearer $Token"}

#Get image Credential from Commander
     Try{
         $credurl = $BaseURL+"/rest/v3/credentials/$imageCredName"   
         $cred = Invoke-RestMethod -Method GET $credurl -Headers $AuthHeader -ContentType 'application/json'
         $creds = $cred.password_credential
         $imageusername = $creds.username 
         $imagepassword = $creds.password
        }
         Catch{
             $Exception = "$_"
             Write-Error "Failed to get credential named $domaincredname from credentials in commander.. Does it exist?"
             Write-Error $Exception
             Exit 1   
         }

#set auth url and body based on auth type for Cyberark
    If ($AuthType -eq "LDAP"){
        $body = "{`n `"username`": `"$UserName`",`n `"password`": `"$Password`",`n `"concurrentSessions`": `"false`"`n}"
        $TokenURL = "https://$Instance/PasswordVault/API/auth/LDAP/Logon"
    }
    Elseif($AuthType -eq "CyberArk"){
        $body = "{`n `"username`": `"$UserName`",`n `"password`": `"$Password`"`n}"
        $TokenURL = "https://$Instance/PasswordVault/API/auth/CyberArk/Logon"
    }
    Elseif($AuthType -eq "RADIUS"){
        $body = "{`n `"Username`": `"$UserName`",`n `"Password`": `"$Password`",`n `"concurrentSessions`": `"true`"`n}"
        $TokenURL = "https://$Instance/PasswordVault/API/auth/radius/Logon"
    }
    Elseif($AuthType -eq "Windows"){
        $body = "{`n `"username`": `"$UserName`",`n `"password`": `"$Password`",`n `"concurrentSessions`": `"false`"`n}"
        $TokenURL = "https://$Instance/PasswordVault/API/auth/Windows/Logon"
    }
    Else{Write-Error "The Supported AuthTypes for CyberArk API are, CyberArk, LDAP, RADIUS, Windows.. Please enter a Valid Auth type"
    }

# Invoke Call to get token
    Try{
        $response = Invoke-RestMethod $TokenURL -Method 'POST' -Headers $headers -Body $body -ContentType 'application/json'
        $Token = $response
        $AuthHeader = @{"Authorization"= $Token}
        }
        Catch{Write-host "Failed to get Auth Token from Cyberark." -ForegroundColor Red
            $Exception = "$_"
            Write-Error $Exception
            Exit 1
        }

#Get Account to see if it already exists in Cyberark.
    Try{
        $AccountlookupUrl =  "https://$Instance/PasswordVault/api/Accounts?search=$Dnsname&searchType=contains"
        $Accountlookup = Invoke-RestMethod $AccountlookupUrl  -Method 'GET' -Headers $AuthHeader -ContentType 'application/json'
        $Accountlookupresult = $Accountlookup.value
        }
        Catch{Write-host "Failed to get Accounts from Cyberark." -ForegroundColor Red
            $Exception = "$_"
            Write-Error $Exception
            Exit 1
        }

#Check and see if the new username is already in the safe
    $ExAccount = $Accountlookupresult | where-object {($_.safename -eq $SafeName) -and ($_.username -eq $newusername) -and ($_.address -eq $address)}
    if($ExAccount.count -ne 0){
        write-host "An account already exists in the safe $SafeName with a username of $username for $address" -ForegroundColor Red
        Exit 1
        }

#Add Account 
     $Body = @"
{
 "name": "$address-$newusername",
 "address": "$address",
 "userName": "$imageusername",
 "platformId": "$PlatformID",
 "safeName": "$SafeName",
 "secretType": "password",
 "secret": "$imagepassword",
 "platformAccountProperties": {
 },
 "secretManagement": {
  "automaticManagementEnabled": true
 }
}
"@
    Try{
    $AddAccounturl = "https://$Instance/PasswordVault/api/Accounts"
    $AddAcctResult = Invoke-RestMethod -uri $AddAccounturl -Method 'POST' -Headers $AuthHeader -Body $body -ContentType 'application/json'
    if($AddAcctResult.id -ne $null){
        Write-host "Account $address has been created sucessfully" -ForegroundColor Green
        Exit 0
        }  
        }Catch{
            Write-host "Failed to Create Account in Cyberark." -ForegroundColor Red
            $Exception = "$_"
            Write-Error $Exception
            Exit 1
        }
 