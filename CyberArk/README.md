# CyberArk Onboard VM/Instance into CyberArk Module
After provisioning an instance this module will Create an entry in add the image Password for consumers to CyberArk to be rotated based on the Safes policy. This is a module that can be used in any order in a completion workflow.  

## Inputs
1. commander_base_url
* Base url for commander "https://localhost"		
2. image_credential_name
* Credential object to be used when creating the Account registration in Cyberark
3. platform_id
* Platform identifier for the account, this must already exist in CyberArk or the request will fail. 
4. safe_name
* Name of the Safe that the account will be created in.
5. cyberark_authtype
* Auth type for the user account used for API calls to CyberArk,  supported types are: CyberArk, LDAP, RADIUS, Windows.
6. cyberark_instance
* DNS address of the CyberArk Server.

## Module Setup and Installation
### [Setup Guide](https://github.com/SnowSoftwareGlobal/cloudmanagement-integrations/blob/main/CyberArk/Commander_Add_Account_Cyberark_v2.pdf)

<br />
<br />

# CyberArk Plug-in Workflow Step Package

This package contains a Commander plug-in workflow step for Querying a CyberArk PAM Server for rotating credentials. The Queried credentials are then used with SSH or WinRM commands against a target VM/Instance.

It can be used with several Commander workflow extension scenarios, which can be found on the Snow Software Support Knowledge Base. It can also be used outside of Commander scenarios.
Changelog

Version 1.6: Adittional Debug for WinRM. Version 1.2: Adittional Debug and ability to auto populate a reason. Version 1.1: Addition of WinRM support. Version 1.0: Initial version.

### [Download Plugin](https://github.com/SnowSoftwareGlobal/cloudmanagement-integrations/blob/main/CyberArk/wfplugins-cyberark-1.6.jar)

## Plug-in steps in this package

    CyberArk SSH
    CyberArk WinRM


Purpose: Run SSH command or WinRM command against a target with rotating Credentials from a CyberArk Server.

Workflows supporting this plug-in step:

    COMMAND, COMPONENT_COMPLETION, SHARED_COMPLETION, CHANGE_COMPLETION

CyberArk SSH Inputs:

    Step Name: Input field for the name of the step

    Step Execution: Drop-down that sets the step execution behavior. By default, steps execute automatically. However, you can set the step to execute only for specific conditions.

    CyberArk server address: Input field for the DNS address of the CyberArk Server.

    Sys Credentials: Input field for the credentials used to Query the CyberArk Server for VM and Instance Credentials

    Ingnore CyberArk Certificate: Check Box to Ignore an Unsigned CyberArk Server Instance in a Dev/Test Scenario

    Authentication Type: Dropdown Input Field to indicate the type of Credential being used to access the CyberArk Server

    Search Name: Input Field for the DNS or Container Name of the target VM or Instance used for lookup in the CyberArk Server.

    Auto Submit Reason: This injects a message(Snow Commander Request)into the password request body if your system is setup to require it.

    SSH Address: Input field for a reachable Address or DNS name of the Target VM or Instance workload

    SSH Port: Input Field Port used for SSH, Typically port 22. If required an alternate could be set.

    Command Elevation: Dropdown Input Field, to select Elevation if it's required on the target VM or Instance with the queried credential type.

    Command Line: Input text field for the Command to run against the Target VM or Instance.

CyberArk WinRM Inputs:

    Step Name: Input field for the name of the step

    Step Execution: Drop-down that sets the step execution behavior. By default, steps execute automatically. However, you can set the step to execute only for specific conditions.

    CyberArk server address: Input field for the DNS address of the CyberArk Server.

    Sys Credentials: Input field for the credentials used to Query the CyberArk Server for VM and Instance Credentials

    Ingnore CyberArk Certificate: Check Box to Ignore an Unsigned CyberArk Server Instance in a Dev/Test Scenario

    Authentication Type: Dropdown Input Field to indicate the type of Credential being used to access the CyberArk Server

    Search Name: Input Field for the DNS or Container Name of the target VM or Instance used for lookup in the CyberArk Server.

    Auto Submit Reason: This injects a message(Snow Commander Request)into the password request body if your system is setup to require it.

    WinRM Address: Input field for a reachable Address or DNS name of the Target VM or Instance workload

    WinRM Port: Input Field Port used for WinRM, Typically port 5985 or 5986. If required an alternate could be set.

    Command Elevation: Dropdown Input Field, to select the WinRM Authentication type as required on the target VM or Instance with the queried credential type.

    Command Line: Input text field for the Command to run against the Target VM or Instance.

## Installation

Plug-in workflow steps are supported with Commander release 8.7 and higher.

See Adding plug-in workflow steps in the Commander documentation to learn how to install this package.
Return codes

    0 - Step completed successfully

## Logging

To change the logging level, add the following named loggers to the Log4j configuration file located at:

<vcommander-install>\tomcat\common\classes\log4j2.xml

    General Utilities
        Loggers:
            <Logger level="DEBUG" name="wfplugins.cyberark.client"/>
            <Logger level="DEBUG" name="wfplugins.cyberark.task"/>
            <Logger level="DEBUG" name="wfplugins.cyberark.ssh"/>
            <Logger level="DEBUG" name="wfplugins.cyberark.winrm.runner"/>
            <Logger level="DEBUG" name="wfplugins.cyberark.winrm.task"/>


*Currently being migrated from [Embotics Git](https://github.com/Embotics)*

### [Commander Documentation](https://docs.snowsoftware.com/commander/index.htm)

### [Commander Knowledge Base](https://community.snowsoftware.com/s/topic/0TO1r000000E5srGAC/commander?tabset-056aa=2)