# Ansible - Add Host to Inventory/Delete Host
Modules to Add and Remove a deployed host from Ansible AWX. 
 
## Requirements:
* In Snow Commander the Advanced Property “embotics.workflow.script.credentials” must be set to true.
* Attributes "Ansible Application ID" and "Ansible Host ID" must exist in Commander Module Import
* Commander 8.10.X or Higher 

## Setup Steps
1. In the Commander Admin UI navigate to “Configuration> Custom Attributes”, Create two text based attributes ```"Ansible Application ID" and "Ansible Host ID"``` which apply to All Types or Services
2. Create a credential in "Configuration > Credentials" to connect to the Ansible API.
3. Navigate to ```Configuration > Command Workflows``` in the Commander Admin UI and select Modules. In the lower right-hand corner of the workflow list grid you will see an import button, import both workflows. 
4. Edit both modules to assign Ansible credentials to the rest steps and set the Ansible Server address, application, description and Inventory where required. 
5. In your Component Completion workflow or Change Completion workflow use the Run Module Step to run either module.

 ## Troubleshooting:
If the workflow Runs but Ansible isn't populated or the workflow fails. Make sure the module inputs are correct then Download the Commander diagnostic Package from ```Help > Support``` latest Entries are at the bottom of the commander.log file.
____

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)
