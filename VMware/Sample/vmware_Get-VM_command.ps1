<#
Requires PS module VMware.VimAutomation.Core on the Commander server.
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"
#> 

$Username = (Get-Item Env:VMWARE_USERNAME).value;
$Password = (Get-Item Env:VMWARE_PASSWORD).value;
$VIServer = '#{target.cloudAccount.address}';
$vmrId ="#{target.remoteId}"
$Module = "VMware.VimAutomation.Core"

if(!($VIServer) -or !($Username) -or !($Password) -or !($vmrId)-or !($Module)){
        Write-error "Please provide vCenter Login information"
        #Exit 1
        }

#Check for Module
    if (Get-Module -ListAvailable -Name "$Module") {
        Import-Module $Module
        Write-Debug "Module $Module is installed."
        } 
        else {
            Write-Error "Module $Module does not appear to be installed, Please install and run again."
            Exit 1
        }

#Setup Credential
    $Credential= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$Username",("$Password" | ConvertTo-SecureString -AsPlainText -Force) 

#Connect to vCenter       
    $Status = Connect-VIServer -Server $VIServer -Credential $credential -Force

#Get-VMdata
    $VMid = "VirtualMachine-"+$VMRid
    $VmData = VMware.VimAutomation.Core\Get-VM -Id $vmId
    Write-host $VmData  
