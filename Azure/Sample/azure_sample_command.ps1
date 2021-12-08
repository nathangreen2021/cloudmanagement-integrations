<#
Requires PS module AZ on the Commander server.
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"
#> 

$subscriptionId = (Get-Item Env:AZURE_SUBSCRIPTION_ID).value
$tenantId = (Get-Item Env:AZURE_TENANT_ID).value
$apiKey = (Get-Item Env:AZURE_API_KEY).value
$ApplicationId = (Get-Item Env:AZURE_APPLICATION_ID).value
$InstanceId ="#{target.remoteId}"
$Module = "AZ"
$RG = "#{target.resourceGroup.name}"

if(!($subscriptionId) -or !($tenantId) -or !($apiKey) -or !($ApplicationId)-or !($Module) -or !($InstanceId)-or !($RG)){
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
    [pscredential]$Credential= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$ApplicationId",("$apiKey" | ConvertTo-SecureString -AsPlainText -Force) 

#Connect to Azure
    $Connect = Connect-AzAccount -Credential $Credential -Subscription $subscriptionId -Tenant $tenantId -ServicePrincipal -Confirm:$false
    if($Connect){
        Write-Debug "Connected to $($Connect[0].Context.Environment.name)"
    }

#Get-VMdata
    $VmName = $InstanceId.Split('/') | select -Last 1
    $VmData = Get-AzVM -Name $vmname -ResourceGroupName $RG
    Write-host $VmData
       