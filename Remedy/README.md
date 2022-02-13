# Commander Integrations - Remedy

Completion Module to Close a work order in remedy and Create Work Order Module (Sample)

Requirements: 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
* BMC Helix ITSM: Service Desk 21.05(as tested, may work with other versions)

Close Work Order Module Installation and Setup:
1. Ensure a credential exists in "Configuration > Credentials" for Remedy 
2. Import the VM Completion Module for closing a work order
2. Open the Module and specify the credential to Connect to Remedy. 
3. Add the module to your Completion workflow specifying the Required parameters for your setup.
4. If the Module fails to run, the comments will contain the errors 

Create Work Order Module (Sample) Installation and Setup:
1. Ensure a credential exists in "Configuration > Credentials" for Remedy 
2. Import the VM Completion Module for closing a work order
2. Open the Module and specify the credential to Connect to Remedy. 
3. Add the module to your Completion workflow specifying the Required parameters for your setup.
4. If the Module fails to run, the comments will contain the errors 

Create CI Module (Sample) Installation and Setup:
1. Ensure a credential exists in "Configuration > Credentials" for Remedy 
2. Import the VM Completion Module for closing a work order
2. Open the Module and specify the credential to Connect to Remedy. 
3. Add the module to your Completion workflow specifying the Required parameters for your setup.
4. If the Module fails to run, the comments will contain the errors 


Note: not all Remedy status transitions are acceptable: 
* https://docs.bmc.com/docs/srm81/about-work-order-status-transitions-225509555.html

____

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)
