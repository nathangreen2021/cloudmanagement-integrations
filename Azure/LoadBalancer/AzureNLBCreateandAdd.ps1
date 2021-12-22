<#
Azure Standard Network Load Balancer creation and configuration
Requires PS module AZ on the Commander server.
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"


This allows the deployment of an Azure Load Balanacer to be deployed as part of the completiong process of A or many VMs.
This will do the following:

Custom Naming for:
* Load Balancer
* Front End
* Back End Pool
* Public IP
* Rule
* Health Probe

Inputs to configure:

* Rules
* Health Probe


#> 

# Captures connection information for the correct Subscription / resource group
$subscriptionId = (Get-Item Env:AZURE_SUBSCRIPTION_ID).value
$tenantId = (Get-Item Env:AZURE_TENANT_ID).value
$apiKey = (Get-Item Env:AZURE_API_KEY).value
$applicationId = (Get-Item Env:AZURE_APPLICATION_ID).value
$instanceId = "#{target.remoteId}"
$resourceGroup = "#{target.resourceGroup.name}"
$module = "AZ"
$vmname = "#{target.deployedName}"


<# This is the custom naming component.  Feel free to modify/change this to suit your needs
Example:
myservername-001 is changed to myservername-LB for the load balancer and so forth.  Please amend to meet your requirements
#>

$AzureLBBackEndPoolName = (("#{inputVariable['Azure LB Back End Pool Name']}").Substring(0,"#{inputVariable['Azure LB Back End Pool Name']}".Length-3))+"BE"
$AzureLBFrontEndName = (("#{inputVariable['Azure LB Front End Name']}").Substring(0,"#{inputVariable['Azure LB Front End Name']}".Length-3))+"FE"
$AzureLBHealthProbeName = (("#{inputVariable['Azure LB Health Probe Name']}").Substring(0,"#{inputVariable['Azure LB Health Probe Name']}".Length-3))+"HP"
$AzureLBName = (("#{inputVariable['Azure LB Name']}").Substring(0,"#{inputVariable['Azure LB Name']}".Length-3))+"LB"
$AzureLBPublicIPName = (("#{inputVariable['Azure LB Public IP Name']}").Substring(0,"#{inputVariable['Azure LB Public IP Name']}".Length-3))+"IP"
$AzureLBRuleName = (("#{inputVariable['Azure LB Rule Name']}").Substring(0,"#{inputVariable['Azure LB Rule Name']}".Length-3))+"RN"


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


#Capture the VM Data for use within the script.  If any of these fail it will provide errors.  Most likely the VM no longer exists.
Try{
    $vmName = $instanceId.Split('/') | select -Last 1
    $vmData = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
    $location = $vmData.Location
    $osType = $vmData.StorageProfile.OsDisk.OsType
    $VMNic = ($vmData.NetworkProfile.NetworkInterfaces.id).Split('/')[-1]
}
Catch{
    $exception = "$_."
    Write-Error $exception
    Exit 3     
}


<# Do checks to see if Load Balancer already exists.  If it does not exist it will create the new Load Balancer, If it already exists, it will
Simply add the VM to the load balancer
#>
$mylb = Get-AzLoadBalancer -Name $AzureLBName -ResourceGroupName $resourceGroup -ErrorAction Ignore
if ($mylb -eq $Null)
    {
    write-host "Load Balancer does not exist in the Subscription, will create and add the VM to it"

##### Create Public IP Address

$publicip = @{
    Name = $AzureLBPublicIPName
    ResourceGroupName = $resourceGroup
    Location = $location
    Sku = 'Standard'
    AllocationMethod = 'static'
    Zone = 1,2,3
}
New-AzPublicIpAddress @publicip

##### Create standard NLB

## Place public IP created in previous steps into variable. ##
$publicIp = Get-AzPublicIpAddress -Name $AzureLBPublicIPName -ResourceGroupName $resourceGroup

## Create load balancer frontend configuration and place in variable. ##
$feip = New-AzLoadBalancerFrontendIpConfig -Name $AzureLBFrontEndName -PublicIpAddress $publicIp

## Create backend address pool configuration and place in variable. ##
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name $AzureLBBackEndPoolName

## Create the health probe and place in variable. ##
$probe = @{
    Name = $AzureLBHealthProbeName
    Protocol = "#{target.settings.customAttribute['Azure LB Health Probe Protocol']}"
    Port = "#{target.settings.customAttribute['Azure LB Health Probe Port']}"
    IntervalInSeconds = '360'
    ProbeCount = '5'
    RequestPath = "#{target.settings.customAttribute['Azure LB Health Probe Request Path']}"
}
$healthprobe = New-AzLoadBalancerProbeConfig @probe

## Create the load balancer rule and place in variable. ##
$lbrule = @{
    Name = $AzureLBRuleName
    Protocol = "#{target.settings.customAttribute['Azure LB Rule Protocol']}"
    FrontendPort = "#{target.settings.customAttribute['Azure LB Rule Front End Port']}"
    BackendPort = "#{target.settings.customAttribute['Azure LB Rule Back End Port']}"
    IdleTimeoutInMinutes = '15'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
}
$rule = New-AzLoadBalancerRuleConfig @lbrule -EnableTcpReset -DisableOutboundSNAT

## Create the load balancer resource. ##
$loadbalancer = @{
    ResourceGroupName = $resourceGroup
    Name = $AzureLBName
    Location = $location
    Sku = "Standard"
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
    LoadBalancingRule = $rule
    Probe = $healthprobe
}
New-AzLoadBalancer @loadbalancer

## Add VM to the BackEnd Pool
$mylb = Get-AzLoadBalancer -Name $AzureLBName -ResourceGroupName $resourceGroup
$ap = Get-AzLoadBalancerBackendAddressPoolConfig -Name $AzureLBBackEndPoolName -LoadBalancer $mylb
#$VMNic = ($VMName.NetworkProfile.NetworkInterfaces.id).Split('/')[-1]
$nic1 = Get-AzNetworkInterface -ResourceGroupName $resourceGroup -Name $VMNic
$nic1.IpConfigurations[0].LoadBalancerBackendAddressPools = $ap
$nic1 | Set-AzNetworkInterface
}
else
    {
        # This is only adding a VM to an existing Load Balancer Back End Pool since the check stated the Load Balancer already exists.
        write-host "Load Balancer already exists, adding VM to back end pool "
        ## Add VM to the BackEnd Pool
        $mylb = Get-AzLoadBalancer -Name $AzureLBName -ResourceGroupName $resourceGroup
        $ap = Get-AzLoadBalancerBackendAddressPoolConfig -Name $AzureLBBackEndPoolName -LoadBalancer $mylb
        $nic1 = Get-AzNetworkInterface -ResourceGroupName $resourceGroup -Name $VMNic
        $nic1.IpConfigurations[0].LoadBalancerBackendAddressPools = $ap
    $nic1 | Set-AzNetworkInterface
    }