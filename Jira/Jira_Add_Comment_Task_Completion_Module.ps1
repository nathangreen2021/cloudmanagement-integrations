<#
Description: Script that Calls out to Jira to add a comment to a task.

Requirements: 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
* Requires Jira Powershell module "JiraPS"
#>

# preamble
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# server configuration
$Server = "#{inputVariable['JiraServer']}"
$project = "#{inputVariable['ProjectKey']}"
$summary = "'#{inputVariable['Summary']}'"
$Comment = "'#{inputVariable['Comment']}'"

# credentials
$Username = $Env:SELECTED_CREDENTIALS_USERNAME
$Password = $Env:SELECTED_CREDENTIALS_PASSWORD
$SecurePassword = ConvertTo-SecureString -AsPlainText -Force $Password
$Credential = New-Object pscredential $Username, $SecurePassword

#Check All Variables Present
if(!($Username) -or !($Password) -or !($Server) -or !($project) -or !($summary) -or !($Comment)){
        Write-error "Please provide all required input variables to execute this workflow"
        Exit 1} 

#Check for Module
    $Module = "JiraPS"
    if (Get-Module -ListAvailable -Name $Module) {
        Import-Module $Module
        Write-Debug "Module $Module is installed."
    } 
    else {
        Write-Error "Module $module does not appear to be installed, Please install and run again."
        Exit 1
    }

# init
Set-JiraConfigServer $Server
New-JiraSession $Credential

#work
$Issue = Get-JiraIssue -Query "project = $project AND summary ~ $summary" -fields "key" , "summary"
$IssueKey = $issue.key
Add-JiraIssueComment -Comment "$Comment" -Issue "$issuekey"
