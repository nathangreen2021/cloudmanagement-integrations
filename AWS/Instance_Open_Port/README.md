# Commander Integrations - Instance Open Port

A Change Completion Workflow, which connects to AWS using the AWSPowershell.Netcore Powershell module and opens a port on the existing Security group for the Instance. 

*Requires PS module AWSPowershell.Netcore on the Commander server. 
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"
*List Attribute on Change Request Form: TCP/UDP
*Regex for CIDR on Change Request Form: ^([0-9]{1,3}\.){3}[0-9]{1,3}($|\/(0|16|24|32))$
*Regex for Port Value on Change Request Form: ^\d+$

*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)