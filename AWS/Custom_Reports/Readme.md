# AWS - Custom Reports
 
## Targeted AWS Cloud Based reports:
1. AWS Waste Reclamation Report
    - This report includes Items such as: Elastic IP addresses that have no associations, Unattached EBS volumes and Snapshots with no originating Volume.
2. AWS Security Hub Enable
    - This Workflow is used to enable Security Hub on the target account prior to running the AWS Security Hub Reccomendations Report workflow.
3. AWS Security Hub Recommendations    
    - This Report is used to provide a view into priority security issues across an AWS account. 

## Requirements
 - AWS PowerShell Module installed on the Commander Server
 - AWS Account must be added with IAM Credentials(not Assume Role)
 - IAM Credential requires read permission on the AWS Account as a minimum.
 - In Snow Commander the Advanced Property “embotics.workflow.script.credentials” must be set to true.
 - In some cases the Execution Policy on the Commander Server must be set to “Unrestricted”

 ## Setup Steps
1. On the Commander Server if you don’t have the Azure PowerShell module installed it can be easily  installed by running the following in PowerShell:
```Install-Module -Name AWSPowerShell.NetCore -AllowClobber -Force```
if you receive a Security error you may need to run this and try again:
```[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12```
2. In the Commander Admin UI navigate to “Configuration> System> Advanced”
Search for ```embotics.workflow.script.credentials``` and set the value to true.
3. Navigate to ```Configuration > Command Workflows``` in the Commander Admin UI. In the lower right-hand corner of the workflow list grid you will see an import button.
4. With the Workflow imported, select it and edit workflow Step # 3. Set the recipient E-mail address that will receive a Hyperlink when the report is complete.
5. Now to run the workflow against a cloud account to generate the report. In Views Select an AWS Cloud account in inventory and then right-click and select Run Workflow from the account-Menu.
6. Select the report you with to run from the workflow list.
7. Once complete, the recipient will receive a link to the report. It’s HTML based and if the report is run again, it will update the existing. If required print the report for refrence later.

 ## Troubleshooting:
If the Report Runs but it’s, empty or the workflow fails. Make sure the PowerShell Module is Installed,Report path is correct then Download the Commander diagnostic Package from ```Help > Support``` latest Entries are at the bottom of the file.

_______ 

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)

