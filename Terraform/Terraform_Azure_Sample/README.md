# Terraform - Azure VM deployment

This Azure example shows you one way to use Commander workflow modules to sync Terraform accounts after a deployment is made, then set resource ownership for Commander portal visibility. This example can be modified for other cloud accounts and can also be used as a starting point for other cloud accounts not managed by Snow Commander.

Requirements:
* Credential in the Commander credential library for connecting to Commander (API User)
* Credential in the Commander credential library named after the AWS subscription that will be used for Change Requests
* Advanced property "embotics.rest.credentials.retrievesensitive" must be set to "True"
* Advanced property "embotics.workflow.script.credentials" must be set to "True"
* Terraform binary Installed on the Commander Server and linked to Terraform Cloud.
    * Binary path for this sample:  "C:\terraform\terraform.exe"
    * https://learn.hashicorp.com/tutorials/terraform/cloud-login
    * You may need to copy your Terraform Cloud token to C:\Users\CommanderService\AppData\Roaming\terraform.d for Commander to be able to connect to TFCloud.
* Commander 9.X or higher 

Deployment workflow modules installation and setup:
1. Ensure a credential exists in "Configuration > Credentials" for Commander API.
2. Import the custom component completion modules, followed by the workflow modules.
3. Open the sync and ownership modules and specify the credential in the dropdown to connect back into the Commander API. 
4. Create a folder for deployments on the  server for this example: "c:\terraform\deployments".
5. Create a folder "Ubuntu_VM_Template" to be copied as a base config or "template" and copy the justvm.tf file into the folder. This will be copied for every deployment and named after the RequestID. 
6. Open the Terraform Deployment module and look at where the variables.tf file get created in the new folder for the deployment. Make sure these match the variables in justvm.tf.
7. In the sample the vmname is "NewTFVM001". This can be a user input field and passed into the module.
8. If the module fails to run, the comments will contain the errors.

____

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)
