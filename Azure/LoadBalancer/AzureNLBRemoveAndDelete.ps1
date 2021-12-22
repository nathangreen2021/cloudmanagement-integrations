<#
Azure Standard Load Balancer Decommission.
Requires PS module AZ on the Commander server.
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"


This script will remove the VM from the back end pool first, then it will check the back end pool to confirm if there are existing VMs. 
If there are no more VMs in the back end pool it will go ahead and delete the Public IP and the Load Balancer
#> 

# Capture connection information for the correct subscription / resource group etc
$subscriptionId = (Get-Item Env:AZURE_SUBSCRIPTION_ID).value
$tenantId = (Get-Item Env:AZURE_TENANT_ID).value
$apiKey = (Get-Item Env:AZURE_API_KEY).value
$applicationId = (Get-Item Env:AZURE_APPLICATION_ID).value
$instanceId = "#{target.remoteId}"
$resourceGroup = "#{target.resourceGroup.name}"
$module = "AZ"
$vmname = "#{target.deployedName}"

if(!($subscriptionId) -or !($tenantId) -or !($apiKey) -or !($applicationId)-or !($module) -or !($instanceId)-or !($resourceGroup)){
        Write-error "Please provide Azure Login information"
        Exit 1
}

#Remove white space for older versions of powershell
$subscriptionId = $subscriptionId -replace "\s", ""
$tenantId = $tenantId -replace "\s", ""
$apiKey = $apiKey -replace "\s", ""
$applicationId = $applicationId -replace "\s", "" 

#Check for Module
if (Get-Module -ListAvailable -Name "$module.*") {
    Import-Module $module
    Write-Debug "Module $module is installed."
} 
else {
    Write-Error "Module $module does not appear to be installed, Please install and run again."
    Exit 2
}

#Credential Object
[pscredential]$credential= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$applicationId",("$apiKey" | ConvertTo-SecureString -AsPlainText -Force) 

#Connect to Azure
$connect = Connect-AzAccount -Credential $credential -Subscription $subscriptionId -Tenant $tenantId -ServicePrincipal -Confirm:$false
if($connect){
    Write-Debug "Connected to $($connect[0].Context.Environment.name)"
}

#Get VM Data and NLB Data. Sleeps have been added during my testing, feel free to remove them if required.
Try{
    #$vmName = $instanceId.Split('/') | select -Last 1
    $vmData = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
    $location = $vmData.Location
    $osType = $vmData.StorageProfile.OsDisk.OsType
    $NetworkInterfaceID = ($vmData.NetworkProfile.NetworkInterfaces.id).Split('/')[-1]
    $VMNic = ($VMData.NetworkProfile.NetworkInterfaces.id).Split('/')[-1]
    $nic1 = Get-AzNetworkInterface -ResourceGroupName $resourceGroup -Name $VMNic
    Start-Sleep -Seconds 10
    
    # NLB Details
    $BackEndPoolForNic1 = $nic1.IpConfigurations.LoadBalancerBackendAddressPools.id
    $BackEndPoolNameForNic1 = $BackEndPoolForNic1.Split('/')[-1]
    $NLBNameforNic1 = $BackEndPoolForNic1.Split('/')[-3]
    $mylb = Get-AzLoadBalancer -Name $NLBNameforNic1 -ResourceGroupName $resourceGroup
    $NLBPublicIPName = ($mylb.FrontendIpConfigurations.publicipaddress.id).Split('/')[-1]
    $BackendIpConfigurations = Get-AzLoadBalancerBackendAddressPool -Name $BackEndPoolNameForNic1 -ResourceGroupName $resourceGroup -LoadBalancerName $NLBNameforNic1
    $ap = Get-AzLoadBalancerBackendAddressPoolConfig -Name $BackEndPoolNameForNic1 -LoadBalancer $mylb
    Start-Sleep -Seconds 10
}
Catch{
    $exception = "$_."
    Write-Error $exception
    Exit 3     
}

#Remove VM from Back End Pool
Try {
write-host "Removing $vmname from $BackEndPoolNameForNic1 Back End Pool"

$nic1 = Get-AzNetworkInterface -ResourceGroupName $resourceGroup -Name $VMNic
$nic1.IpConfigurations[0].LoadBalancerBackendAddressPools = $Null
$nic1 | Set-AzNetworkInterface
Start-Sleep -Seconds 10
}
Catch{
    $exception = "$_."
    Write-Error $exception
    Exit 3     
}

$BackendIpConfigurations = Get-AzLoadBalancerBackendAddressPool -Name $BackEndPoolNameForNic1 -ResourceGroupName $resourceGroup -LoadBalancerName $NLBNameforNic1

if ($BackendIpConfigurations.BackendIpConfigurations)
    {
        write-host "$BackEndPoolNameForNic1 Still has Servers associated, skipping deletion of $NLBNameforNic1"
    }
else
    {
        write-host "No VMs associated to $BackEndPoolNameForNic1, removing Load Balancer $NLBNameforNic1 from resource group $resourceGroup "
        Remove-AzLoadBalancer -Name $NLBNameforNic1 -ResourceGroupName $resourceGroup  -force
        Start-Sleep -Seconds 10
        $BackendIpConfigurations = Get-AzLoadBalancerBackendAddressPool -Name $BackEndPoolNameForNic1 -ResourceGroupName $resourceGroup -LoadBalancerName $NLBNameforNic1
        write-host "Removing Public IP Address Named $NLBPublicIPName from Resource Group $resourceGroup"
        Remove-AzPublicIpAddress -Name $NLBPublicIPName -ResourceGroupName $resourceGroup -force
        
    }
