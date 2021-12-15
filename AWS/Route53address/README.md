# Commander Integrations Create/Delete/Change Route53 Address in Completion Workflow

Workflow module samples which connect to AWS and Commander using "VCommanderRestClient","VCommander","AWSPowerShell" Powershell modules.
1. Creates an Elastic IP for the instance and an A record in Route53.
2. Delete an A record in AWS Route53. 
3. Change Completion Module to Delete an A record in AWS Route53. 

* Requires PS modules "VCommanderRestClient","VCommander","AWSPowerShell" on the Commander server. 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"

Installation and Setup:
1. Create a VM Attributes called AWS Route53 DNS Address","AWS Elastic IP set","AWS Elastic IP Address" if they are not found they will be created on the first run of the module. 
2. Create a Credential in the credential library that mathces a Commander Users Credential that can see all Cloud Accounts. 
3. Import the Completion Workflow Module.
4. Open the Completion Workflow Module and specify the credential to Connect to Commanders API as well as all of the default values for your Environment.
5. Add the Run Module step to an existing Completion workflow module and specify the imported and modified Module.

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)