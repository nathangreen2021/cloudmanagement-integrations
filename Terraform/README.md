# Terraform - Samples

These examples show how to use Commander workflow modules to sync Terraform accounts after a deployment is made, then set resource ownership and make a change request for Deployed Terraform resources based on the state file. These examples can be used as a starting point for other cloud accounts not managed by Snow Commander.

Requirements:
* Credential in the Commander credential library for connecting to Commander (API User)
* Advanced property "embotics.rest.credentials.retrievesensitive" must be set to "True"
* Advanced property "embotics.workflow.script.credentials" must be set to "True"
* Appropriate Variable Set in Terraform Cloud for the target cloud account [TF Cloud Varaiable Sets](https://www.terraform.io/cloud-docs/workspaces/variables/managing-variables#edit-variable-sets)
* Terraform binary Installed on the Commander Server and linked to Terraform Cloud
    * Binary path for this sample:  "C:\terraform\terraform.exe"
    * https://learn.hashicorp.com/tutorials/terraform/cloud-login
    * You may need to copy your Terraform Cloud token to C:\Users\CommanderService\AppData\Roaming\terraform.d for Commander to be able to connect to TFCloud
* Commander 9.X or higher 

Examples
* [AWS Sample](https://github.com/SnowSoftwareGlobal/cloudmanagement-integrations/blob/main/Terraform/Terraform_AWS_Sample/README.md)
* [Azure Sample](https://github.com/SnowSoftwareGlobal/cloudmanagement-integrations/blob/main/Terraform/Terraform_Azure_Sample/README.md)

____


*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)
