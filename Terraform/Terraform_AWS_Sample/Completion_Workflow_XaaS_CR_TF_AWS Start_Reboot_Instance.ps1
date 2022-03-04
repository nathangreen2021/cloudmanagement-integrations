#Commander Base Configuration
$BaseURL = 'https://localhost'
$user = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME).value;
$pass = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$BypassCert = "yes"
$WaitforSync = 10 #in seconds 


#Target Information
$Context = "#{target.context.instances[0].attributes.arn}"
$Deployedname = "#{target.deployedName}"  #not needed but good to know it resolves. 
 
 #Check All Variables Presenta
if (!($BaseURL ) -or !($WaitforSync) -or !($user) -or !($pass) -or !($BypassCert) -or !($Context) -or !($Deployedname)) {
        Write-error "Please provide all required input variables to execute this workflow"
        Exit 1} 


#Check for Module
    $Module = "AWSPowerShell.NetCore"
    if (Get-Module -ListAvailable -Name $Module) {
        Import-Module AWSPowershell.netcore -WarningAction Ignore
        Write-Debug "Module $Module is installed."
    } 
    else {
        Write-Error "Module $module does not appear to be installed, Please install and run again."
        Exit 1
    }
#Breakdown ARN into usable variables
    $account = $Context.split(":")[4]
    $region = $Context.split(":")[3]
    $Instance = $Context.split("/")[-1]

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
[Net.ServicePointManager]::Expect100Continue = $true
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

#Get Auth Token
    $Token = $null
    $TokenEndpoint = "/rest/v3/tokens"
    $TokenURL = $BaseURL+$TokenEndpoint
    $TokenBody = "{
                ""username"": ""$user"",
                ""password"": ""$pass"" 
                }"
    $TokenResult = Invoke-RestMethod -Method POST $TokenURL -Body $TokenBody -ContentType 'application/json'
    $Token = $TokenResult.token
    $AuthHeader = @{"Authorization"= "Bearer $Token"}

#Get Credential for subscription by subscription ID
     Try{
         $credurl = $BaseURL+"/rest/v3/credentials/$account"   
         $cred = Invoke-RestMethod -Method GET $credurl -Headers $AuthHeader -ContentType 'application/json'
         $creds = $cred.password_credential
         $awsaccesskey = $creds.username 
         $awssecret = $creds.password
        }
         Catch{
             $Exception = "$_"
             Write-Error "Failed to get credential named $account from credentials in commander.. Does it exist?"
             Write-Error $Exception
             Exit 1   
         } 

#Login
    Set-AWSCredentials -AccessKey $awsaccesskey -SecretKey $awssecret -StoreAs SnowCommander
    $Connect = Initialize-AWSDefaults -ProfileName SnowCommander -Region $Region

#Restart Instance
    $InstanceData = Get-EC2Instance -Region $Region -InstanceId $Instance
    if(($InstanceData.Instances.InstanceId) -eq $Instance){
        $InstanceState = (Get-EC2InstanceStatus -InstanceId $instance).InstanceState
        if(!$InstanceState){
            Write-host "Instance has no Status Attempting to start the Instance"
            $Start = Start-EC2Instance -InstanceId $Instance -Force -Confirm:$false
            start-sleep $WaitforSync
            $InstanceState = (Get-EC2InstanceStatus -InstanceId $instance).InstanceState
            $CurrentState = $InstanceState.Name.Value

            Write-host "Instance is now $CurrentState"
        }
        elseif($InstanceState.name.value -eq "running"){
            Write-host "Attempting to restart the running Instance $Instance"
            $Restart = Restart-EC2Instance -InstanceId $Instance -Force -Confirm:$false
        }
        else{Write-host "The Instance is not in a Stopped or Running State, nothing to do."
        }
    }
 