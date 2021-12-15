<# 
Script to assign a Route53 address along with ElasticIP to an AWS EC2 instance post deployment
* Requires PS modules "VCommanderRestClient","VCommander","AWSPowerShell" on the Commander server. 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
#>

#AWS Information
$AccessKey = (Get-Item Env:AWS_ACCESS_KEY_ID).value
$SecretKey = (Get-Item Env:AWS_SECRET_ACCESS_KEY).value
$Instance = '#{target.remoteId}' 
$Region = '#{target.region.name}' 
$ForceCreateFlag = 'yes'  #Create elastic IP if it does not exist. defaulton the target(yes)

#Commander Information
$user = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value;
$pass = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$CommanderServer = "localhost"  
$vCmdrID = '#{target.id}' 
$VMname = '#{target.deployedName}' 

# Attributes Created if they don't exist already
$Attrib = "AWS Route53 DNS Address"     # used to store the route 53 address for visability in portal and automated cleanup.
$Attrib1 = "AWS Elastic IP set"         # Yes/No of elastic IP configured
$Attrib2 =  "AWS Elastic IP Address"    # AWS Elastic IP Assigned

#Route53 Entry Params
$Domain = "Your.Route53.Domain"
$Type = "A"
$TTL = "300"
$Comment = "Created by Snow Commander"

if(!($Accesskey) -or !($SecretKey) -or !($Region) -or !($Instance) -or !($ForceCreateFlag)){
        Write-error "Please provide the required AWS information"
        Exit 1
        } 

if (!($CommanderServer) -or !($vCmdrID) -or !($Attrib) -or !($Attrib1) -or !($Attrib2) -or !($user) -or !($pass)) {
        Write-error "Please provide the required Commander information"
        Exit 1
        } 

if(!($Domain) -or !($Type) -or !($TTL) -or !($Comment)){
        Write-error "Please provide the required Route53 information"
        Exit 1
        }  


#Remove and re-add the modules 
        Write-Host "Loading Modules"
        $module = @("VCommanderRestClient","VCommander","AWSPowerShell" )
        ForEach($Modulename in $module){
                If (-not (Get-Module -name $moduleName)) {Import-Module -Name $moduleName 
                } else {Remove-Module $moduleName
                        Import-Module -Name $moduleName
                        }
                        Start-Sleep 1
                }
#Connect to AWS in the specified region. 
    $AWSCred=(Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs Commander)
    Set-DefaultAWSRegion -Region $Region
    Initialize-AWSDefaults -ProfileName Commander -Region $Region

#Setup Credential
    $Credential= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$User",("$Pass" | ConvertTo-SecureString -AsPlainText -Force)  
    write-host  "Cred object created for $user"

#Connecting to vCommander
    $Global:SERVICE_HOST = $CommanderServer
    $Global:REQUEST_HEADERS =@{}
    $Global:BASE_SERVICE_URI = $Global:BASE_SERVICE_URI_PATTERN.Replace("{service_host}",$Global:SERVICE_HOST)   
    $Global:CREDENTIAL = $Credential
    VCommander\Set-IgnoreSslErrors
    $Connect = Connect-Client
    if($Connect -ne "True"){
        Write-Host "Not Connected to vCommander, please perform Login to continue"
        Exit 1;
        }

    #Check and see if the Attribute exists in vCommander: Create if it does not exist.
    $CheckAttrib = (Get-CustomAttributes).CustomAttributeCollection.CustomAttributes | Where-Object{$_.Name -EQ  $Attrib}
    If ($CheckAttrib.displayName -ne  $Attrib)
        {   Write-host "Creating Custom attribute - $Attrib"
            $caObject = New-DTOTemplateObject -DTOTagName "CustomAttribute"
            #Specify attribute value
            $caObject.CustomAttribute.name="$Attrib"
            $caObject.CustomAttribute.description=""
            $caObject.CustomAttribute.targetManagedObjectTypes = @("ALL")
            $caObject.CustomAttribute.portalEditable = "false"
            $caObject.CustomAttribute.id = -1
            $caObject.CustomAttribute.allowedValues =  @()
            $createdCa = New-CustomAttribute -customAttributeDTo $caObject
            }
            Start-Sleep 1 #Wait to be sure the job completes before proceeding

    #Check and see if the Attribute exists in vCommander: Create if it does not exist.
    $CheckAttrib1 = (Get-CustomAttributes).CustomAttributeCollection.CustomAttributes | Where-Object{$_.Name -EQ  $Attrib1}
    If ($CheckAttrib1.displayName -ne  $Attrib1)
        {   Write-host "Creating Custom attribute - $Attrib1"
            $caObject1 = New-DTOTemplateObject -DTOTagName "CustomAttribute"
            #Specify attribute value
            $caObject1.CustomAttribute.name="$Attrib1"
            $caObject1.CustomAttribute.description=""
            $caObject1.CustomAttribute.targetManagedObjectTypes = @("ALL")
            $caObject1.CustomAttribute.portalEditable = "false"
            $caObject1.CustomAttribute.id = -1
            $caObject1.CustomAttribute.allowedValues = @( "Yes", "No" )
            $createdCa1 = New-CustomAttribute -customAttributeDTo $caObject1
            }
            Start-Sleep 1 #Wait to be sure the job completes before proceeding

    #Check and see if the Attribute exists in vCommander: Create if it does not exist.
    $CheckAttrib2 = (Get-CustomAttributes).CustomAttributeCollection.CustomAttributes | Where-Object{$_.Name -EQ  $Attrib2}
    If ($CheckAttrib2.displayName -ne  $Attrib2)
        {   Write-host "Creating Custom attribute - $Attrib2"
            $caObject2 = New-DTOTemplateObject -DTOTagName "CustomAttribute"
            #Specify attribute value
            $caObject2.CustomAttribute.name="$Attrib2"
            $caObject2.CustomAttribute.description=""
            $caObject2.CustomAttribute.targetManagedObjectTypes = @("ALL")
            $caObject2.CustomAttribute.portalEditable = "false"
            $caObject2.CustomAttribute.id = -1
            $caObject2.CustomAttribute.allowedValues = @()
            $createdCa2 = New-CustomAttribute -customAttributeDTo $caObject2
            }
            Start-Sleep 1 #Wait to be sure the job completes before proceeding

#Check of user entered domain without the dot, and add it
    if ($Domain.Substring($Domain.Length-1) -ne ".") {
        $DomainDot = $Domain + "."
    } else {
        $DomainDot = $Domain
    }

#Check Instance for Elastic IP to continue.
    $Elastic_Address = Get-EC2Address -Filter @{ Name="instance-id";Value="$Instance" }
    $Non_ElasticpublicIP = (Get-EC2Instance -InstanceId $Instance).Instances.PublicIpAddress
     IF(($Elastic_Address -eq $null) -and ($Non_ElasticpublicIP -eq $null) -and ($ForceCreateFlag -eq 'yes')){
        Try{$address = New-EC2Address -Domain "Vpc"
            $Status = Register-EC2Address -InstanceId $Instance -AllocationId $address.AllocationId
            $value = $address.PublicIp
            #Set Custom attribute if Elastic IP set 
            $attributeDTO1 = New-DTOTemplateObject -DTOTagName "CustomAttribute"
            $attributeDTO1.CustomAttribute.allowedValues = @() #not important
            $attributeDTO1.CustomAttribute.description = $null #not important
            $attributeDTO1.CustomAttribute.targetManagedObjectTypes = @()  #not important
            $attributeDTO1.CustomAttribute.name= $Attrib1
            $attributeDTO1.CustomAttribute.value = "Yes"
            $result = Set-Attribute -vmId  $vCmdrID -customAttributeDTo $attributeDTO1
            }
            Catch{$error[0] | Format-List -Force
                 Exit 1;
                 }}
        Elseif(($Elastic_Address -eq $null) -and ($Non_ElasticpublicIP -ne $null)){
                    #Set Custom attribute if Elastic IP set 
                    $attributeDTO1 = New-DTOTemplateObject -DTOTagName "CustomAttribute"
                    $attributeDTO1.CustomAttribute.allowedValues = @() #not important
                    $attributeDTO1.CustomAttribute.description = $null #not important
                    $attributeDTO1.CustomAttribute.targetManagedObjectTypes = @()  #not important
                    $attributeDTO1.CustomAttribute.name= $Attrib1
                    $attributeDTO1.CustomAttribute.value = "Yes"
                    $result = Set-Attribute -vmId  $vCmdrID -customAttributeDTo $attributeDTO1
                    $Value = $Non_ElasticpublicIP
                    }
        Elseif(($Elastic_Address -ne $null) -and ($Non_ElasticpublicIP -ne $null)){
                    #Set Custom attribute if Elastic IP set 
                    $attributeDTO1 = New-DTOTemplateObject -DTOTagName "CustomAttribute"
                    $attributeDTO1.CustomAttribute.allowedValues = @() #not important
                    $attributeDTO1.CustomAttribute.description = $null #not important
                    $attributeDTO1.CustomAttribute.targetManagedObjectTypes = @()  #not important
                    $attributeDTO1.CustomAttribute.name= $Attrib1
                    $attributeDTO1.CustomAttribute.value = "Yes"
                    $result = Set-Attribute -vmId  $vCmdrID -customAttributeDTo $attributeDTO1
                    $Value = $Elastic_Address
                    }

        Else {Write-host "Exiting because the target instance does not have an elastic IP"
            Exit 1
            }
    
#Remove the Spaces from the name if they exist
    $VMname = $Vmname.replace(' ','')

# Create new objects for R53 update
    $Change = New-Object Amazon.Route53.Model.Change
    $Change.Action = "UPSERT"
        # CREATE: Creates a resource record set that has the specified values.
        # DELETE: Deletes an existing resource record set that has the specified values.
        # UPSERT: If a resource record set doesn't already exist, AWS creates it. If it does, Route 53 updates it with values in the request.
    $Change.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
    $Change.ResourceRecordSet.Name = "$VMname.$Domain"
    $Change.ResourceRecordSet.Type = $Type
    $Change.ResourceRecordSet.Region = $Region
    $Change.ResourceRecordSet.TTL = $TTL
    $Change.ResourceRecordSet.SetIdentifier = "vCommander"
    #$Change.ResourceRecordSet.ResourceRecords.Add(@{Value=$Value})
    $Change.ResourceRecordSet.ResourceRecords.Add(@{Value=if ($Type -eq "TXT") {"""$Value"""} else {$Value}})

# Get hosted zone
    $HostedZone = Get-R53HostedZones | Where-Object {$_.Name -eq $DomainDot}

# Set final parameters and execute
    $Parameters = @{
        HostedZoneId = $HostedZone.Id
        ChangeBatch_Change = $Change # Object
        ChangeBatch_Comment = $Comment # "Edited A record"
    }
    $Result = Edit-R53ResourceRecordSet @Parameters

# Set Custom attribute value in vCommander for the Instance
    Try{$attributeDTO = New-DTOTemplateObject -DTOTagName "CustomAttribute"
        $attributeDTO.CustomAttribute.allowedValues = @() #not important
        $attributeDTO.CustomAttribute.description = $null #not important
        $attributeDTO.CustomAttribute.targetManagedObjectTypes = @()  #not important
        $attributeDTO.CustomAttribute.name= "$Attrib"
        $attributeDTO.CustomAttribute.value = "$VMname.$Domain"
        Set-Attribute -vmId $vCmdrID -customAttributeDTo $attributeDTO

        #Set Custom attribute of Route 53 DNS Address  
        $attributeDTO2 = New-DTOTemplateObject -DTOTagName "CustomAttribute"
        $attributeDTO2.CustomAttribute.allowedValues = @() #not important
        $attributeDTO2.CustomAttribute.description = $null #not important
        $attributeDTO2.CustomAttribute.targetManagedObjectTypes = @()  #not important
        $attributeDTO2.CustomAttribute.name= $Attrib2
        $attributeDTO2.CustomAttribute.value = $Value
        $result = Set-Attribute -vmId  $vCmdrID -customAttributeDTo $attributeDTO2
        }
        Catch{
        Write-host "Failed to set $Attrib value."
        $error[0] | Format-List -Force
        Exit 1;
        }
    
#End