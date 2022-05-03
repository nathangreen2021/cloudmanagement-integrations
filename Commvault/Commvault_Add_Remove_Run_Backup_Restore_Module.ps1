<#
Commvault - Add VM to Policy, Remove VM From Policy and Backup Now
Requirements: 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
* Requires Commvault PowerShell modules to be installed on the Commander Server
    - https://documentation.commvault.com/hitachivantara/v11/essential/124529_installing_commvault_powershell_sdk_from_github_most_recent_version_of_module.html
#>

$username = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME).value; 
$password = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value; 
$SERVER = "#{inputVariable['Commvault Server URL']}"  
$Client = "#{target.settings.dynamicList['Client Name']}"
$Subclient = "#{target.settings.dynamicList['Subclient']}"
$Target = "#{target.deployedName}"
#Action Supports 4 values "SetPolicy", "RemovePolicy", "RunNow", "Restore"
$Action = "#{inputVariable['Action']}"
#{Yes:No} to bypass unsigned cert on the target server. 
$BypassCert = "yes"     


##########################################################################################
if (!($UserName) -or !($Password) -or !($SERVER) -or !($Action) -or !($BypassCert)) {
        Write-error "Please provide the required information for Commvault"
        Exit 1
        }

#Check for Modules
$Modules = "Commvault.RESTSession", "Commvault.VirtualServer"
ForEach ($Module in $Modules) {
    if (Get-Module -ListAvailable -Name "$Module") {
        Import-Module $Module
        Write-host "Module $Module is installed."
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
$Cred= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($username,$secpass)

#Connect To Instance
Connect-CVServer -Credential $Cred -Server $Server

if ($Action -eq "SetPolicy") {
    #Add VM to Backup Policy
    if(!($Client) -or !($Subclient) -or !($Target)){
        Write-error "Please provide commvault backup information"
        Exit 1
    } 
    Write-host "Running $action for VM $target"
    Add-CVVirtualMachine -ClientName $Client -SubclientName $Subclient -EntityType VM -Entity $Target

}
ElseIf ($Action -eq "RemovePolicy") {
    #Remove VM from Backup Policy
    if(!($Client) -or !($Subclient) -or !($Target)){
        Write-error "Please provide commvault backup information"
        Exit 1
    } 
    Write-host "Running $action for VM $target"
    Remove-CVVirtualMachine -ClientName $Client -SubclientName $subclient -EntityType VM -Entity $Target

}
ElseIf ($Action -eq "RunNow") {
    #Backup VM Immediately
    if(!($Client) -or !($Target)){
        Write-error "Please provide commvault backup information"
        Exit 1
    } 
    Write-host "Running $action for VM $target"
    Backup-CVVirtualMachine -ClientName $Client -Name $Target -Force
}
ElseIf ($Action -eq "Restore") {
    #Backup VM Immediately
    if(!($Client) -or !($Target)){
        Write-error "Please provide commvault backup information"
        Exit 1
    } 
    Write-host "Running $action for VM $target"
    Restore-CVVirtualMachine -ClientName $client -SubclientName $Subclient -Name $Target -PowerOnAfterRestore -OverwriteExisting -Force
}
Else{
    Write-host "Action $action didn't not match any conditions to run agains the vm $target"
    Exit 1
}