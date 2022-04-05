# Azure  - Custom Reports
 
## Targeted Azure Cloud Based reports:
1. Azure Waste Reclamation Report
  - This report includes items such as: unattached Managed Disks, Unassigned vNics and (.vhd) Blob Storage that’s not currently associated to a VM (Lease Status = Unlocked) reports the estimated yearly savings. 
2. Azure RI Report
 - Reports on potential RI savings pulled from from Azure, can be configured for 1 or 3 year terms. 
3. Azure Snapshot Report
 - Outputs Snapshots older than X Days(configurable) and lists the potential yearly savings if the snapshots were removed.

## Requirements
 - Requires PS module AZ on the Commander server.
 - Commander 8.6.0 or higher
 - Advanced property "embotics.workflow.script.credentials" must be set to "true"


## Setup Steps
1. On the Commander Server if you don’t have the Azure PowerShell module installed it can be easily  installed by running the following in PowerShell:
```Install-Module -Name AZ -AllowClobber -Force```
if you receive a Security error you may need to run this and try again:
```[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12```
2. In the Commander Admin UI navigate to “Configuration> System> Advanced”
Search for ```embotics.workflow.script.credentials``` and set the value to true.
3. Navigate to ```Configuration > Command Workflows``` in the Commander Admin UI. In the lower right-hand corner of the workflow list grid you will see an import button.
4. With the Workflow imported, select it and edit workflow Step # 3. Set the recipient E-mail address that will receive a Hyperlink when the report is complete.
5. Now to run the workflow against a cloud account to generate the report. In Views Select an Azure Cloud account in inventory and then right-click and select Run Workflow from the account-Menu.
6. Select the report you with to run from the workflow list.
7. Once complete, the recipient will receive a link to the report. It’s HTML based and if the report is run again, it will update the existing. If required print the report for refrence later.



 
## Troubleshooting:
If the Report Runs but it’s, empty or the workflow fails. Make sure the PowerShell Module is Installed,Report path is correct then Download the Commander diagnostic Package from ```Help > Support``` latest Entries are at the bottom of the file.


_______ 

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)



