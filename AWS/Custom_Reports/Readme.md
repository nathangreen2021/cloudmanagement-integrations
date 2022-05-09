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

 

 ## Troubleshooting:
If the Report Runs but it’s, empty or the workflow fails. Make sure the PowerShell Module is Installed, Report path is correct then Download the Commander diagnostic Package from ```Help > Support``` latest Entries are at the bottom of the commander.log file.

_______ 

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)

