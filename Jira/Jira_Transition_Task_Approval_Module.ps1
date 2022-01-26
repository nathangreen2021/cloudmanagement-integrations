<#
Description: Script that Calls out to Jira to transition a task.

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
$TransitionToStatus = "#{inputVariable['TransitionToStatus']}"

# credentials
$Username = $Env:SELECTED_CREDENTIALS_USERNAME
$Password = $Env:SELECTED_CREDENTIALS_PASSWORD
$SecurePassword = ConvertTo-SecureString -AsPlainText -Force $Password
$Credential = New-Object pscredential $Username, $SecurePassword

#Check All Variables Present
if(!($Username) -or !($Password) -or !($Server) -or !($project) -or !($summary) -or !($TransitionToStatus)){
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
write-host $issuekey
$InvokeJiraIssueTransitionSplat = @{ Issue = $IssueKey }
$Issue = Get-JiraIssue $IssueKey
$Transitions = Select-Object -ExpandProperty Transition -InputObject $Issue
$DesiredTransition = $Transitions | Where-Object {
    $ResultStatus = Select-Object -ExpandProperty ResultStatus -InputObject $_ | Select-Object -ExpandProperty Name
    $ResultStatus -eq $TransitionToStatus
}

if ($DesiredTransition) {
    $InvokeJiraIssueTransitionSplat.Transition = $DesiredTransition
}
else {
    $IssueStatus = Select-Object -ExpandProperty Status -InputObject $Issue
    $AvailableStatuses = (
        $Transitions | Select-Object -ExpandProperty ResultStatus | Select-Object -ExpandProperty Name
    ) -join ", "

    Write-Error (
        "Issue $IssueKey does not have a transition from its current status of $IssueStatus to $TransitionToStatus." +
        " The available statuses are: $AvailableStatuses."
    )
}

Invoke-JiraIssueTransition @InvokeJiraIssueTransitionSplat