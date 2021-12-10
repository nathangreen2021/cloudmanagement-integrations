# Commander Integrations - Snapshot Cleanup

A Command Module and Workflow, which connects to Commander Via rest and retrieves all VM's with a Specific Tag, if the VM's withhthe Tag Value set to "Yes" have a snapshot older than the specified number of days. A delete snapshot task automatically gets created. 

Requirements:
* Requires a VM List Attribute called "SnapshotPolicy" with Available Values {Yes:No}
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
* A Credential in the credential library that can be used to talk to the Commandeer API and See All the VMware VM that will be checked. 

Installation and Setup:
1. Create a VM List Attribute called "SnapshotPolicy" with Available Values {Yes:No}
2. Create a Credential in the credential library that mathces a Users Credential that can see all VMware Cloud Accounts that need to have Snapshots Cleaned up. 
3. Import the Command Workflow Module
4. Import the Command Workflow
5. Open the Command Workflow Module and specify the credentail to Connect to Commanders API. 
6. Run the Command workflow and Check the Comments of the resulting workflow. 
7. If Sucessful this can be Schedualed on a regular basis to keep your Environment as Snapshot free as you wish. 

Policy Configuration:
1. Create a policy to automatically set the Attribute value when new workloads are deployed on parts of your infrastructure.

Notes: 
* If you have backup software which is snapshot based we do not recommend schedualing the workflow during your backup window. 

____

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)
