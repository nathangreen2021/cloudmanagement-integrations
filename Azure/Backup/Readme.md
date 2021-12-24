# Completion modules to Add and Remove Azure Instance from Backup Vault

These completion modules contain steps to add VMs to backup policies in Azure.
 - Requires PS module AZ on the Commander server.
 - Commander 8.6.0 or higher
 - Advanced property "embotics.workflow.script.credentials" must be set to "true"

## Changelog

**Version 1.0:** Initial version.

## Completion modules
+ Add VM to backup policy in region (Add Azure Instance to Backup Vault.json)
+ Remove VM from Backup Policy in Region (Delete Instance from Azure Backup Vault.json)

### Azure - Add VM to Backup Policy
**Purpose:** To add a VM to a backup policy in Azure

**Workflows supporting this modules:**

  * VM Completion Workflow

**Inputs:**
  * Azure - Add VM to Backup Policy
    *  Backup Vault Name
    *  Policy Name
    *  Workload Type 
 

### Remove VM from backup policy in region
**Purpose:** To remove individual VMs from a Backup policy in region. 

**Workflows supporting these modules:**

  * Change Request Completion Workflow
 

    
**Usage:**

Azure - Add VM to Backup Policy

- Import the Azure - Add VM to Backup Policy module into the completion modules section of Self-Service
- Add the Azure - Add VM to Backup Policy module to your VM Completion Workflow. 
- Set the Condition of the workflow as follows:  #{target.cloudAccount.type} -eq "ms_arm"


 NOTE: The above can be user selectable if you require, can be list based attributes depending on how restrictive you would like to be and where it makes sense.  You will need to change this to an attribute in the Module if you want to make it a static list.
 
Azure - Remove VM from Backup module

- Import the Azure - Remove VM from Backup module into the completion modules section of Self-Service
- Add this to your deommission work flow as required
- Note: if there is no backup for the selected Instance it will exit clean with a proper message.
- Set the Condition of the workflow as follows:  #{target.cloudAccount.type} -eq "ms_arm"




