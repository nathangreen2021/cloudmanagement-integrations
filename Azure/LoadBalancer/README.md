# Completion modules for Create and Decommission Azure Standard Network Load Balancer 

These completion modules contain steps to create a standard network load balancer in Azure with basic configurations and to also remove VMs and delete Loadbalancers when back end pools are empty
 - Requires PS module AZ on the Commander server.
 - Commander 8.6.0 or higher
 - Advanced property "embotics.workflow.script.credentials" must be set to "true"

## Changelog

**Version 1.0:** Initial version.

## Completion modules
+ Create standard NLB and add VMs
+ Decommission VMs from the NLB and clean up when back end pool is empty

### Create Standard Network Load Balancer
**Purpose:** To create Azure Standard Network load balancers as part of your deployment and add VMs into the Load Balancer

**Workflows supporting these modules:**

  * VM Completion

### Remove VM from Standard Network Load Balancer and Decommission when Back End pool is empty
**Purpose:** To remove individual VMs from a Back End Pool associated to your load balancer. If the pool is empty, then it will delete the Load Balancer and Public IP Address

**Workflows supporting these modules:**

  * Change Request Completion
 

**Inputs:**
  * Azure - Load Balancer Creation
    *  Azure LB Back End Pool Name
	*  Azure LB Front End Name
	*  Azure LB Health Probe Name
	*  Azure LB Name
	*  Azure LB Public IP Name
	*  Azure LB Rule Name
    
**Usage:**

Azure - Load Balancer Creation module

- Import the Azure - Load Balancer Creation module into the completion modules section of Self-Service
- Add the Azure - Load Balancer Creation module to your VM Completion Workflow. 
 * OPTIONAL : Set the Condition of the workflow as follows - (NOTE: A custom attribute on your blueprint must exist for Load Balanced, This should be set to YES and not user selectable or on the form)
 
 (#{target.cloudAccount.type} -eq "ms_arm") -and (#{target.settings.customAttribute['Load Balanced']} -eq "yes")

- Create attributes for the following and add to your Blueprint:
  * Azure LB Health Probe Port
  * Azure LB Health Probe Protocol
  * Azure LB Health Probe Request Path
  * Azure LB Rule Back End Port
  * Azure LB Rule Front End Port
  * Azure LB Rule Protocol
  * Load Balanced
  
 NOTE: The above are user selectable if you require, these can be text or lists depending on how restrictive you would like to be and where it makes sense
 
- Set the above up on the form as required except for Load Balanced (Which should be set to YES by default IF you wanted to use this in a workflow with other items and to be selective on if it runs or not)

Azure - Load Balancer Decommission module

- Import the Azure - Load Balancer Decommission module into the completion modules section of Self-Service
- Add this to your deommission work flow as required
 * OPTIONAL : Set the Condition of the workflow as follows - (NOTE: A custom attribute on your blueprint must exist for Load Balanced, This should be set to YES and not user selectable or on the form)
 
 (#{target.cloudAccount.type} -eq "ms_arm") -and (#{target.settings.customAttribute['Load Balanced']} -eq "yes")


## Installation

Completion modules are supported with Commander release 8.6 and higher. 

## Return codes

### Generic return codes
+ **0** - *Step completed successfully*
+ **All Other Returns** - *Step produced an error, see Workflow Comments for error details*

## Logging
To change the logging level, add the following named loggers to the Log4j configuration file located at: 

<vcommander-install>\tomcat\common\classes\log4j2.xml 


