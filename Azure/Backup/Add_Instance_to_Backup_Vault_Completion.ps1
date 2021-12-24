<#
Azure Add VM to Policies in Azure backup Vault.
Requires PS module AZ on the Commander server.
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"
Form attribute with a List of Policies Available to the Vault in the Instance region
#> 

$subscriptionId = (Get-Item Env:AZURE_SUBSCRIPTION_ID).value
$tenantId = (Get-Item Env:AZURE_TENANT_ID).value
$apiKey = (Get-Item Env:AZURE_API_KEY).value
$applicationId = (Get-Item Env:AZURE_APPLICATION_ID).value
$instanceId = "#{target.remoteId}"
$Region = "#{target.region.name}"
$resourceGroup = "#{target.resourceGroup.name}"
$module = "AZ"
$policyName = "#{inputVariable['policyname']}"
$vaultName = "#{inputVariable['vaultName']}" 
$WorkloadType = "#{inputVariable['workloadType']}" 

if (!($subscriptionId) -or !($tenantId) -or !($apiKey) -or !($applicationId) -or !($module) -or !($instanceId) -or !($resourceGroup) -or !($Region)) {
    Write-error "Please provide Azure Login information"
    Exit 1
}
if (!($policyName) -or !($vaultName) -or !($WorkloadType)) {
    Write-error "Please provide Azure Backup Vault information"
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
    Exit 1
}

#Build Azure Credential Object
[pscredential]$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$applicationId", ("$apiKey" | ConvertTo-SecureString -AsPlainText -Force) 

#Connect to Azure
$connect = Connect-AzAccount -Credential $credential -Subscription $subscriptionId -Tenant $tenantId -ServicePrincipal -Confirm:$false -WarningAction 0 
if ($connect) {
    Write-Debug "Connected to $($connect[0].Context.Environment.name)"
}

#Capture VM Information From ID
$vmName = $instanceId.Split('/') | select -Last 1
$vmData = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
$Region = $vmData.Location
$osType = $vmData.StorageProfile.OsDisk.OsType

#Get and verify vault information
$Vaults = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroup | where-object { $_.Location -like $Region } | select-object Name -ExpandProperty Name
if (!$vaults) {
    Write-Error "No Vaults found, Cannot Continue"
    Exit 1
}
elseif ($vaults -notcontains $vaultName) {
    Write-Error "$vaultName not found, in the region $region, Cannot Continue"
    Exit 1 
}

#Get and Verify Policy
Get-AzRecoveryServicesVault -Name $vaultName | Set-AzRecoveryServicesVaultContext
$policys = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policyName | Where-object { $_.WorkloadType -eq $WorkloadType }
if (!$policys) {
    Write-Error "No Policy mathing that workflow type found, Cannot Continue"
    Exit 1
}
elseif ($policys.Name -notcontains $policyName) {
    Write-Error "$policyName not found, in the $vaultName Vault, Cannot Continue"
    Exit 1 
}

#Set Context and policy
Get-AzRecoveryServicesVault -Name $vaultName | Set-AzRecoveryServicesVaultContext
$policycontext = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policyName
Set-AzRecoveryServicesVaultContext -Vault (Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroup -Name $vaultName) 

#Enable VM Backup - specifying policy, resource group & VM
Enable-AzRecoveryServicesBackupProtection  -ResourceGroupName $resourceGroup  -Name $vmname -Policy $policycontext 
#pause for Azure to update (30 second to be safe)
Start-sleep -Seconds 30
$backupStatus = Get-AzRecoveryServicesBackupContainer -ContainerType $WorkloadType -FriendlyName $vmname -ResourceGroupName $resourceGroup -WarningAction 0 
if (!$backupStatus) {
    Write-Error "Failed to get backup status, Please contact an Admin to ensure everything is setup as expected"
    Exit 1
}
$Status = $backupStatus.Status
$buType = $backupStatus.ContainerType
Write-Output "The Instance $vmName has been assigned the $buType Policy $policyName in the vault $vaultName with a status of $Status"
   
 
