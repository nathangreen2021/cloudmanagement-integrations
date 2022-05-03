$username = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME).value; 
$password = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value; 
$Server = "yourCommvaultserver.local"
$Clientname = "#{target.settings.dynamicList['Client Name']}"
#{Yes:No} to bypass unsigned cert on the target server. 
$BypassCert = "yes"    

##########################################################################################
if (!($username) -or !($password) -or !($Server) -or !($BypassCert) -or !($Clientname)) {
    Write-error "Please provide the required information for Commvault"
    Exit 1
}

#Check for Modules
$Modules = "Commvault.RESTSession", "Commvault.JobManager"
ForEach ($Module in $Modules) {
    if (Get-Module -ListAvailable -Name "$Module") {
        Import-Module $Module
        Write-debug "Module $Module is installed."
    } 
    else {
        Write-Error "Module $module does not appear to be installed, Please install and run again."
        Exit 1
    }
}  

#Bypass Unsigned Cert for API connections. 
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

#Create Credential object for Commvault 
$secpass = ConvertTo-SecureString "$Password" -AsPlainText -force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($username, $secpass)

#Connect To Instance
Connect-CVServer -Credential $Cred -Server $Server

#Get SubClientList and Output jsonarray
$json = Get-CVSubClient -ClientName $Clientname
ConvertTo-JSON @($json.subclientName)