$subscriptionId = (Get-Item Env:AZURE_SUBSCRIPTION_ID).value
$tenantId = (Get-Item Env:AZURE_TENANT_ID).value
$apiKey = (Get-Item Env:AZURE_API_KEY).value
$applicationId = (Get-Item Env:AZURE_APPLICATION_ID).value
$instanceId = "#{target.remoteId}"
$Region = "#{target.region.name}"
$resourceGroup = "#{target.resourceGroup.name}"
$module = "AZ"
$WorkloadType = "AzureVM" 

if (!($subscriptionId) -or !($tenantId) -or !($apiKey) -or !($applicationId) -or !($module) -or !($instanceId) -or !($resourceGroup) -or !($Region) -or !($WorkloadType)){
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

#Check if instance is configured to be backed up
    $BackupData = Get-AzRecoveryServicesBackupStatus -Name $vmName -ResourceGroupName $resourceGroup -Type $WorkloadType
    if (!$BackupData){
        Write-host "Instance $vmname is currently not assigned to a vault, Nothing to Cleanup"
        Exit 0
    }
    $VaultName = ($BackupData.VaultId).Split('/') | select -Last 1
    $VaultID = $BackupData.VaultId

#Set Policy
    Get-AzRecoveryServicesVault -Name $vaultName | Set-AzRecoveryServicesVaultContext
    #$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
    #$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroup -Name $vaultName
    $Container = Get-AzRecoveryServicesBackupContainer -ContainerType $WorkloadType -Status Registered -FriendlyName $vmName -VaultId $VaultID -WarningAction 0 
    $BackupItem = Get-AzRecoveryServicesBackupItem -Container $Container -WorkloadType $WorkloadType -VaultId $VaultID -WarningAction 0 

#Disable Backup
    $BackupDisable = Disable-AzRecoveryServicesBackupProtection -Item $BackupItem -VaultId $VaultID -RemoveRecoveryPoints -Confirm:$False -Force -WarningAction 0 
    $Status = $BackupDisable.Status
    $Operation = $BackupDisable.Operation
    Write-Output "The operation $Operation on Instance $vmName for Vault $VaultName has $Status, Note: Soft Deletes are still present if not disabled on the vault"
  
