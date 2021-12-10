<#
Sample Get AWS EC2 Instance
*Requires PS module AWSPowershell.Netcore on the Commander server. 
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"
#>
 

$AccessKey = (Get-Item Env:AWS_ACCESS_KEY_ID).value
$SecretKey = (Get-Item Env:AWS_SECRET_ACCESS_KEY).value
$InstanceID = "#{target.remoteId}"
$Region = "#{target.region.name}"

 
 
if(!($Accesskey) -or !($SecretKey) -or !($Region) -or !($InstanceID)){
        Write-error "Please provide AWS Login information"
        Exit 1
        } 
        
#Remove white space for older versions of powershell
$Accesskey = $Accesskey -replace "\s", ""
$SecretKey = $SecretKey -replace "\s", ""

#Check for Module
    $Module = "AWSPowerShell.NetCore"
    if (Get-Module -ListAvailable -Name $Module) {
        Import-Module AWSPowershell.netcore
        Write-Debug "Module $Module is installed."
    } 
    else {
        Write-Error "Module $module does not appear to be installed, Please install and run again."
        Exit 1
    }

#Login
    Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs SnowCommander
    $Connect = Initialize-AWSDefaults -ProfileName SnowCommander -Region $Region

#Setup Ingress Rule
    $InstanceData = Get-EC2Instance -Region $Region -InstanceId $InstanceID
    Write-host $InstanceData
       