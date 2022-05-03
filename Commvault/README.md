# Commvault Add/Remove/RunNow/Restore Modules

Completion and Change Completion Workflow modules that utilize Dynamic form Lists to allow the Requester to select the Client and Subclient. These Dynamic Form lists can be bypassed if required with static data or list based attributes. These modules provide 4 specific backup functions: "SetPolicy", "RemovePolicy", "RunNow", "Restore" which can all be driven by form based inputs. 


Requirements: 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
* Commvault Powershell module installed on the Commander server 
    - https://documentation.commvault.com/hitachivantara/v11/essential/124529_installing_commvault_powershell_sdk_from_github_most_recent_version_of_module.html

## Inputs
1. Commvault Server URL
* In the format ```commvault.domain.local```
2. Client Name
* The lient name of the Commvault Backup by default this example uses the form based Dynamic list which outputs the variable ```#{target.settings.dynamicList['Client Name']}``` though this can be hardcoded or passed in from an attribute. 
3. SubClient Name
* The Subclient name of the Commvault Backup by default this example uses the form based Dynamic list which outputs the variable ```#{target.settings.dynamicList['Subclient']}``` though this can be hardcoded or passed in from an attribute.
4. Commvault Action
* Supports 4 values "SetPolicy", "RemovePolicy", "RunNow", "Restore"
5. Bypass Unsigned Certificate
* Bypass unsigned Certificate of the target API if required. Default is set to "Yes"

Module Installation and Setup:

1. In Commander ensure a credential exists in "Configuration > Credentials" to connect to the Commvault API.
2. Import the Modules.
3. Edit both modules to specify the credential created in step 1 on the Execute Embedded Script step. 
4. Define the relevant input variables to match that of your Change Request Form. Example below:
	- Client Name: ```#{target.settings.dynamicList['Client Name']}```
	- Commvault Server URL: ```yourcommvaultserver.com ```
	- SubClient Name: ```#{target.settings.dynamicList['Subclient']}```
5. In your Component Completion workflow or Change Completion workflow use the Run Module Step to run either module.

Note: Using dynamic lists Allow the user to pull the relevant Client Names & Subclient Names from your Commvault server. Please refer to Dynamic_Commvault_ClientName.ps1 & Dynamic_Commvault_SubClientName.ps1 to utilize.

____

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)
