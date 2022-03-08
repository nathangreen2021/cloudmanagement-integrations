<#
AWS Instance CR - Open TCP/UDP Ports.
*Requires PS module AWSPowershell.Netcore on the Commander server. 
*Commander 8.6.0 or higher
*Advanced property "embotics.workflow.script.credentials" must be set to "true"
Requires three form Attributes:
List Attribute on Change request form: TCP/UDP
Regex for CIDR on Change Request Form: ^([0-9]{1,3}\.){3}[0-9]{1,3}($|\/(0|16|24|32))$
Regex for Port Value: ^\d+$
#>
 

$AccessKey = (Get-Item Env:AWS_ACCESS_KEY_ID).value
$SecretKey = (Get-Item Env:AWS_SECRET_ACCESS_KEY).value
$InstanceID = "#{target.remoteId}"
$Region = "#{target.region.name}"
$ipCidr = "#{target.settings.customAttribute['CIDR Input']}"
$Protocol = "#{target.settings.customAttribute['Protocol']}"
$Port = "#{target.settings.customAttribute['Port']}"
 
 
if(!($Accesskey) -or !($SecretKey) -or !($Region) -or !($InstanceID) -or !($ipCidr) -or !($Protocol)-or !($Port)){
        Write-error "Please provide AWS Login information"
        Exit 1
        } 
        
#Remove white space for older versions of powershell
$Accesskey = $Accesskey -replace "\s", ""
$SecretKey = $SecretKey -replace "\s", ""

#Check for Module
    $Module = "AWSPowerShell.NetCore"
    if (Get-Module -ListAvailable -Name $Module) {
        Import-Module AWSPowershell.netcore
        Write-Debug "Module $Module is installed."
    } 
    else {
        Write-Error "Module $module does not appear to be installed, Please install and run again."
        Exit 1
    }

#Login
    Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs SnowCommander
    $Connect = Initialize-AWSDefaults -ProfileName SnowCommander -Region $Region

#Setup Ingress Rule
$IngressChange = New-Object Amazon.EC2.Model.IpPermission
$IngressChange.IpProtocol = $Protocol
$IngressChange.FromPort = $Port
$IngressChange.ToPort = $port
$IngressChange.IpRanges.Add("$ipCidr")

#Get Instance Data/SG
    $InstanceData = Get-EC2Instance -Region $Region -InstanceId $InstanceID
    $SecurityGroup = $InstanceData.RunningInstance.SecurityGroups.GroupId
    Write-host $securitygroup
        if($SecurityGroup.count -eq 1){
            Try{
                Grant-EC2SecurityGroupIngress -GroupId $SecurityGroup -PassThru -Region $Region -IpPermission @($IngressChange) -force
                }
                Catch{
                    $Exception = "$_.Exception"
                    if($Exception -like "*already exists*"){
                        write-host "Ingress Port rule already exists... nothing to do" -ForegroundColor Red
                        Exit 0}
                    else{Write-error "$Exception"
                        Exit 1
                        }
    
                }
            }
        elseif($SecurityGroup.count -gt 1){
            Write-Error "Instance has more than one assigned Security Group, Not making any Changes!"
            Exit 1
            }
        else{Write-Error "Something has gone wrong regarding Security Group Count, Not making any Changes!"
            Exit 1
            } 
