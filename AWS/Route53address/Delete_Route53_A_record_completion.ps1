<# 
Script to Delete a Route53 address in AWS
 Requires PS modules "VCommanderRestClient","VCommander","AWSPowerShell" on the Commander server. 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
#>

#AWS Information
$AccessKey = (Get-Item Env:AWS_ACCESS_KEY_ID).value
$SecretKey = (Get-Item Env:AWS_SECRET_ACCESS_KEY).value
$Region = '#{target.region.name}' 

#Commander Information
$user = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value;
$pass = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$CommanderServer = "localhost"  
$vCmdrID = '#{target.id}' 

# Attributes Created if they don't exist already
$Attrib = "AWS Route53 DNS Address"     # used to store the route 53 address for visability in portal and automated cleanup.
$Attrib1 = "AWS Elastic IP set"         # Yes/No of elastic IP configured
$Attrib2 =  "AWS Elastic IP Address"    # AWS Elastic IP Assigned

if(!($Accesskey) -or !($SecretKey) -or !($Region)){
        Write-error "Please provide the required AWS information"
        Exit 1
        } 

if (!($CommanderServer) -or !($vCmdrID) -or !($Attrib) -or !($Attrib1) -or !($Attrib2) -or !($user) -or !($pass)) {
        Write-error "Please provide the required Commander information"
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
    $AWSCred = (Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs vCommander)
    Set-DefaultAWSRegion -Region $Region
    Initialize-AWSDefaults -ProfileName vCommander -Region $Region

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

#Pull Domain from R53address variable
    $vmDnsarray = @($R53Address.split(".",2))
    $Domain = $vmDnsarray[1]

#Check if domain has trailing dot,else add it
    if ($Domain.Substring($Domain.Length-1) -ne ".") {
        $DomainDot = $Domain + "."
    } else {
        $DomainDot = $Domain
    }

#Check if Record has trailing dot,else add it
    if ($R53Address.Substring($R53Address.Length-1) -ne ".") {
        $R53AddressDot = $R53Address + "."
    } else {
        $R53AddressDot = $R53Address
    }

#Check Route53 for the asddress to continue.
    $zones = Get-R53HostedZones | Select-Object name,ID | Where-Object {$_.Name -eq $DomainDot}
    $ZoneID = (($Zones.id).Split('/'))[2]
    $ZoneRecords  = (Get-R53ResourceRecordSet -HostedZoneId $ZoneID).ResourceRecordSets.Name
    IF ($ZoneRecords -contains $R53AddressDot){
        }
        Else{Write-Host "Domain Record for $R53AddressDot does not exist in $DomainDot"
             Exit 0
             }

#Verify DNS object in Route 53 
    $RecordSets = Get-R53ResourceRecordSet -HostedZoneId $Zones.ID -startRecordName $R53Address -MaxItems 1 
        if($RecordSets.ResourceRecordSets -and $RecordSets.ResourceRecordSets.Name -eq "$R53AddressDot" )
        {   $CurrentIP = $RecordSets.ResourceRecordSets.ResourceRecords.Value
	        $CurrentTTL = $RecordSets.ResourceRecordSets.TTL
	        $RecordType = $RecordSets.ResourceRecordSets.Type.Value
	        Write-Output "$Fqdn's IP address is currently $CurrentIP .... Proceeding to modification process!";
        }
        else{
	        Write-Output "$R53AddressDot no found! Nothing to do.";
	        Exit 0;
            }

#Construct objects to identify current record
        $TargetRecord = $RecordSets.ResourceRecordSets;
        $rr = New-Object Amazon.Route53.Model.ResourceRecord
        $rr.Value = $currentIP
        $rrs = New-Object Amazon.Route53.Model.ResourceRecordSet
        $rrs.Name = $R53AddressDot
        $rrs.Type = $RecordType
        $rrs.TTL = $CurrentTTL
        $rrs.ResourceRecords = $rr
 
#Deletes the record set
        $Status = Edit-R53ResourceRecordSet -HostedZoneId $Zones.ID  -ChangeBatch_Changes @( @{Action="DELETE";ResourceRecordSet=$rrs} ) 

#Verify Deletion
        [int]$CurIteration = 0;
        [bool]$DeleteConfirmed = $false;
        do{
	        $RecordSets = Get-R53ResourceRecordSet -HostedZoneId $Zones.ID -startRecordName $R53AddressDot -MaxItems 1
	        if($RecordSets.ResourceRecordSets -and $RecordSets.ResourceRecordSets.Name -eq "$R53AddressDot")
	        {$CurIteration+=1;
		     Write-Output "Waiting before trying to verify that Record was deleted... "
		     Start-Sleep -Seconds 3;
	        }
	        else
	        {
		    #Record is deleted!
		    $DeleteConfirmed = $true;
		    Write-Output "Record: $R53AddressDot was successfully deleted!"

            # Set Custom attribute value in vCommander for the Instance
            Try{$attributeDTO = New-DTOTemplateObject -DTOTagName "CustomAttribute"
                $attributeDTO.CustomAttribute.allowedValues = @() #not important
                $attributeDTO.CustomAttribute.description = $null #not important
                $attributeDTO.CustomAttribute.targetManagedObjectTypes = @()  #not important
                $attributeDTO.CustomAttribute.name= "$Attrib"
                $attributeDTO.CustomAttribute.value = ""
                Set-Attribute -vmId $vCmdrID -customAttributeDTo $attributeDTO

                #Set Custom attribute if Elastic IP set 
                $attributeDTO1 = New-DTOTemplateObject -DTOTagName "CustomAttribute"
                $attributeDTO1.CustomAttribute.allowedValues = @() #not important
                $attributeDTO1.CustomAttribute.description = $null #not important
                $attributeDTO1.CustomAttribute.targetManagedObjectTypes = @()  #not important
                $attributeDTO1.CustomAttribute.name= $Attrib1
                $attributeDTO1.CustomAttribute.value = "No"
                $result = Set-Attribute -vmId  $vCmdrID -customAttributeDTo $attributeDTO1

                #Set Custom attribute of Route 53 DNS Address  
                $attributeDTO2 = New-DTOTemplateObject -DTOTagName "CustomAttribute"
                $attributeDTO2.CustomAttribute.allowedValues = @() #not important
                $attributeDTO2.CustomAttribute.description = $null #not important
                $attributeDTO2.CustomAttribute.targetManagedObjectTypes = @()  #not important
                $attributeDTO2.CustomAttribute.name= $Attrib2
                $attributeDTO2.CustomAttribute.value = ""
                $result = Set-Attribute -vmId  $vCmdrID -customAttributeDTo $attributeDTO2
                }
                Catch{
                    Write-host "Failed to set $Attrib value. $result"
                    $error[0] | Format-List -Force
                    Exit 1;
                }
	        }
            }
        while($CurIteration -lt 60 -and $DeleteConfirmed -eq $false)
        if($CurIteration -ge 60)
            {
	        Write-Output "Failed to detect whether or not DNS record was deleted. Process timed-out.";
	        Exit 1;
            }