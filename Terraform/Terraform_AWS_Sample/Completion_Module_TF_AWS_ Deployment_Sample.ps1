<#
Description: Script that copies a TF Config from another folder, creates a new Variables.tf and then runs Init/Apply
Requirements: 
-Snow Comamnder 9.0.0 or higher
-Powershell or PWSH 5.1 or greater
-Terraform binary installed on the commander server located at c:\terraform\terraform.exe and linked to Terraform Cloud.
--https://learn.hashicorp.com/tutorials/terraform/cloud-login 
- you might need to copy your TerraformCloud token to C:\Users\CommanderService\AppData\Roaming\terraform.d for Commander to be able to connect to TFCloud.
#>

$Requestid = "#{request.id}"
$Template = "#{inputVariable['template_folder_clone']}"
$Deployment = "#{inputVariable['deploymentfilelocation']}"
$Terraformexe = "#{inputVariable['terraform_Exe_path']}"
$InstanceName = "#{inputVariable['InstanceName']}"
$TF_Organization = "#{inputVariable['terraform_organization']}"
$Region = "#{inputVariable['region']}"
$Port = "#{inputVariable['webport']}"

if(!($Requestid) -or !($Template ) -or !($Deployment) -or !($Terraformexe) -or !($InstanceName) -or !($TF_Organization) -or !($Region) -or !($port)){ 
        Write-error "Please provide Remedy information to close the workorder"
        Exit 1
        }
        
#$DebugPreference="Continue"
$ErrorActionPreference = "Stop"

$DeploymentName = "$requestid"
$Folderlocation = "$Deployment" + "\" + $DeploymentName
$outputFile = "$Folderlocation"+"\"+"output.log"
Write-host "Output will be saved to: $outputfile"

#Check if Deployment location exists
    if(!$Deployment){
        Write-host "Folder does not exist creating...."
        New-Item -Path "$Deployment" -ItemType "directory"
            if($Deployment){
                Write-host "Folder $Deployment created sucesfully"
            }
            Else{Write-host "Folder wasn't created as expected, please see administrator."
            }
    }

#Check for Duplicate state folder
   
    #Check if Deployment location exists
    if(Test-Path -Path $Folderlocation){
        Write-Error "Folder already exists.... Something has gone terribly wrong."
        Exit 1
    }

#Copy Base File to New folder
    Copy-Item -Path $Template -Destination $Folderlocation -Recurse -Force -Confirm:$False

#overwrite the default Variables.tf
$Values = @"
terraform {
  cloud {
    organization = "$TF_Organization"

    workspaces {
      name = "$DeploymentName"
    }
  }
}
    variable "instance_type"{
      type = string
      default = "t2.micro"
    }
    variable "server_port" {
      description = "The port the server will use for HTTP requests"
      type        = number
      default     = "$Port"
    }
    variable "aws_region" {
      type    = string
      default = "$Region"
    }
    variable "instancename"{
        type = string
        default = "$InstanceName"
    }
    variable "instancename-sg"{
        type = string
        default = "$InstanceName-sg"
    }

"@
    New-Item -Path $Folderlocation -Name variables.tf -ItemType "file" -Value $values -Force -Confirm:$false

#Setup init params    
    Write-Host "Terraform Path: $Folderlocation"
    $initparams = @()
    $initparams += "init"

#Run the terraform process to load modules and init the system
    try {
        Write-Host "Running Terraform Init process"
        Start-Process -FilePath $Terraformexe -WorkingDirectory $Folderlocation -ArgumentList $initparams -wait -RedirectStandardOutput $outputFile -NoNewWindow
    }
    catch {
        Write-Error "Terraform was not initialized successfully"  
        Exit 1 
    }

#Read the result of the initialization call
    try {
        Write-Host "Loading Terraform Init results"
        $initResults = Get-Content $outputFile
    }
    catch {
        Write-Error "Terraform init results could not be loaded"  
        Exit 1
    }

#Check if the initializaion has completed
    $search = ($initResults | Select-String -Pattern 'Terraform Cloud has been successfully initialized').Matches.Success
    if ($search) {
        Write-Host "Terraform was successfully initialized"
    }
    else {
        Write-Error "Terraform init results, do not contain: 'Terraform Cloud has been successfully initialized'"  
        Exit 1   
    }

#Setup Apply Commands(Apply)
    $applyparam = @()
    $applyparam += "apply"
    $applyparam += "-input=false"
    $applyparam += "-auto-approve"


#Run the terraform process to load modules and init the system
    Start-Process -FilePath $Terraformexe -WorkingDirectory $Folderlocation -ArgumentList $applyparam -wait -RedirectStandardOutput $outputFile

#Read the result of the initialization call
    $deployResults = Get-Content $outputFile

#Check if the initializaion has completed
    if ($deployResults -like '*Apply complete!*') {
        Write-Host "Terraform template was successfully deployed"
    }
    else {
        Write-Host "Terraform template was not deployed successfully"
        Exit 1
    }