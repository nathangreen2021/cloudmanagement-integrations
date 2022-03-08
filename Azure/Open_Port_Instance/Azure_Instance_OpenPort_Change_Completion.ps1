<#
Azure Instance CR - Open TCP/UDP Ports.
Requires PS module AZ on the Commander server.
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"
Requires three form Attributes:
List Attribute on Change Request Form: TCP/UDP
Regex for CIDR on Change Request Form: ^([0-9]{1,3}\.){3}[0-9]{1,3}($|\/(0|16|24|32))$
Regex for Port Value on Change Request Form: ^\d+$
#> 

$subscriptionId = (Get-Item Env:AZURE_SUBSCRIPTION_ID).value
$tenantId = (Get-Item Env:AZURE_TENANT_ID).value
$apiKey = (Get-Item Env:AZURE_API_KEY).value
$ApplicationId = (Get-Item Env:AZURE_APPLICATION_ID).value
$InstanceId = "#{target.remoteId}"
$Module = "AZ"
$RG = "#{target.resourceGroup.name}"
$ipCidr = "#{target.settings.customAttribute['CIDR Input']}"
$Protocol = "#{target.settings.customAttribute['Protocol']}"
$Port = "#{target.settings.customAttribute['Port']}" 

if (!($subscriptionId) -or !($tenantId) -or !($apiKey) -or !($ApplicationId) -or !($Module) -or !($InstanceId) -or !($RG)) {
    Write-error "Please provide Azure Login information"
    #Exit 1
}

#Remove white space for older versions of powershell
$subscriptionId = $subscriptionId -replace "\s", ""
$tenantId = $tenantId -replace "\s", ""
$apiKey = $apiKey -replace "\s", ""
$ApplicationId = $ApplicationId -replace "\s", "" 

#Check for Module
if (Get-Module -ListAvailable -Name "$Module.*") {
    Import-Module $Module
    Write-Debug "Module $Module is installed."
} 
else {
    Write-Error "Module $module does not appear to be installed, Please install and run again."
    Exit 1
}

#Credential Object
[pscredential]$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$ApplicationId", ("$apiKey" | ConvertTo-SecureString -AsPlainText -Force) 

#Connect to Azure
$Connect = Connect-AzAccount -Credential $Credential -Subscription $subscriptionId -Tenant $tenantId -ServicePrincipal -Confirm:$false
if ($Connect) {
    Write-Debug "Connected to $($Connect[0].Context.Environment.name)"
}

#Get-VMdata
Try {
    $VmName = $InstanceId.Split('/') | select -Last 1
    $Vmdata = Get-AzVM -Name $vmname -ResourceGroupName $RG
    $location = $vmdata.Location
}
Catch {
    $Exception = "$_."
    Write-Error $Exception
    Exit 1     
}
$vmnics = $vmdata.NetworkProfile.NetworkInterfaces.id
if ($vmnics.count -gt 1) {
    write-error "Instance has more than one vNic, Exiting instead of modifying the incorrect Nic. " -ForegroundColor Red
    Exit 1    
}
else {
    $vNicName = $vmnics.Split('/') | select -Last 1
    $vNic = Get-AzNetworkInterface -ResourceGroupName $RG  -Name $vNicName
}
     
# Get NSG if it exists and modify it, Else Create a New NSG with the requested rules. 
if ($vNic.NetworkSecurityGroup -eq $null) {
    $NsgName = $VmName + "-nsg"
    $RuleName = $VmName + "-rule"
    Try {    
        $nsgrule = New-AzNetworkSecurityRuleConfig -Name $RuleName -Access Allow -Protocol $Protocol -Direction Inbound -Priority 101 -SourceAddressPrefix $ipCidr -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $Port
        $nsgresult = New-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $rg  -Location  $location -Confirm:$false -Force -SecurityRules $nsgrule
        $vNic.NetworkSecurityGroup = $nsgresult
        $vNic | Set-AzNetworkInterface 
    }
    Catch {
        $Exception = "$_.Exception"
        Write-Error $Exception
        Exit 1     
    }
    Write-host "NSG changes will take a few to be active"        
}
elseif ($vnic.NetworkSecurityGroup -ne $null) {
    Try {
        $RuleName = ("$Protocol-$port-rule").ToLower()
        $aznsg = ($vnic.NetworkSecurityGroup.Id).Split('/') | select -Last 1
        $nsgconfig = Get-AzNetworkSecurityGroup -Name $aznsg -ResourceGroupName $rg -verbose
        $nextPriority = ($nsgconfig.SecurityRules.priority | Select-object -Last 1) + 1
        $nsgrule = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsgconfig -Name $RuleName -Description $RuleName -Access Allow -Protocol $Protocol -Direction Inbound -Priority $nextPriority -SourceAddressPrefix $ipCidr -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange @($Port) | Set-AzNetworkSecurityGroup -Verbose
        $nsgrule 
    }
    Catch {
        $Exception = "$_.Exception"
        Write-Error $Exception
        Exit 1     
    }
    Write-host "NSG changes will take a few to be active"          
}
else {
} 
