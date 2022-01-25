# Commander Integrations - phpIPAM

Approval and Change Completion Modules. Approval used in the approval workflow to inject a Json body into the request for each VMware VM in a request that will get added to the customization spec. 

The Change Completion module for Decomissioning a VM and removing the provided address from phpIPAM. 

Requirements:
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
* Advanced property “embotics.rest.credentials.retrivesensitive” must be set to "true"
* phpIPAM 1.3.1 or greater 
* Only for use with VMware and customization specs. 

Approval Module Installation and Setup:

1. Ensure a credential exists in "Configuration > Credentials" for phpIPAM 
2. Import the Approval Module for pulling the next available address from phpIPAM
2. Open the Module and specify the credential to Connect to phpIPAM. 
3. Add the module to your Approval workflow specifying the Required parameters for your setup.
4. If the Module fails to run, the comments will contain the error when posting to Commander. 

Change Completion Module Installation and Setup:

1. Import the Change Completion Module
2. Open the Module and specify the credential to Connect to phpIPAM. 
3. Add the module to your decomissioning module specifying the Required parameters for your setup.
4. On a sucessful run the comments will contain the output from the delete rest call to phpIPAM. 

Notes: 
* If you have backup software which is snapshot based we do not recommend schedualing the workflow during your backup window. 

____

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)
