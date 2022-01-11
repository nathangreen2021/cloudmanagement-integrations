<#
Script to Assign or Remove an Elastic IP from an AWS EC2 instance
* Requires PS modules "AWSPowerShell.netcore" on the Commander server. 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
#>

#AWS Information
$AccessKey = (Get-Item Env:AWS_ACCESS_KEY_ID).value
$SecretKey = (Get-Item Env:AWS_SECRET_ACCESS_KEY).value
$Instance = '#{target.remoteId}' 
$Region = '#{target.region.name}' 
$Action = "#{inputVariable['action']}"  #Action Value {Assign:Remove}
$APIwait = "#{inputVariable['apiwait']}"  #time to wait for AWS to update in seconds 

if(!($Accesskey) -or !($SecretKey) -or !($Region) -or !($Instance) -or !($Action)){
        Write-error "Please provide the required AWS information"
        Exit 1
        } 

#Remove and re-add the modules 
        Write-Host "Loading Modules"
        $module = @("AWSPowerShell.netcore" )
        ForEach($Modulename in $module){
                If (-not (Get-Module -name $moduleName)) {Import-Module -Name $moduleName 
                } else {Remove-Module $moduleName
                        Import-Module -Name $moduleName
                        }
                        Start-Sleep 1
                }

#Connect to AWS in the specified region. 
    Set-AWSCredentials -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs vCommander
    Set-DefaultAWSRegion -Region $Region
    Initialize-AWSDefaults -ProfileName vCommander -Region $Region

#Get-Instance Termination status
    $PublicEIP = (Get-EC2Instance -InstanceId $Instance -Region $Region).RunningInstance | Select-Object -ExpandProperty PublicIpAddress

#Assign Elastic IP address
    Try{
        IF($PublicEIP -eq $null -and $Action -eq "Assign"){
            $address = New-EC2Address -Domain "Vpc"
            $Status = Register-EC2Address -InstanceId $Instance -AllocationId $address.AllocationId
            #Small wait just to be sure the api updates
            Start-sleep $APIwait 
            $PublicEIP = (Get-EC2Instance -InstanceId $Instance -Region $Region).RunningInstance | Select-Object -ExpandProperty PublicIpAddress  
         Write-Host "Elastic IP $PublicEIP has been assigned to instance $instance" 
            Exit 0
        }

#Remove Elastic IP address
         ElseIF ($PublicEIP -ne $null -and $Action -eq "Remove"){
            $unassigned = Get-EC2Address -Filter @{ Name="public-ip";Value=$PublicEIP } 
            $Associd = $unassigned.AssociationId
            Unregister-EC2Address -AssociationId $Associd
            Remove-EC2Address -AllocationId $unassigned.AllocationId -Force
            #Small wait just to be sure the api updates
            Start-sleep $APIwait 
            $PIP = (Get-EC2Instance -InstanceId $Instance -Region $Region).RunningInstance | Select-Object -ExpandProperty PublicIpAddress  
            if($pip -eq $null){
                 Write-Host "Elastic IP $PublicEIP has been removed from instance $instance" 
            }
            Exit 0
         
        }
        ElseIF($PublicEIP -ne $null -and $Action -eq "Assign"){
            Write-Host "Elastic IP $PublicEIP is already assigned to instance $instance"
            Exit 0 
        }
    
        ElseIF($PublicEIP -eq $null -and $Action -eq "Remove"){
            Write-Host "There is no ElasticIP assigned to $Instance, nothing to do." 
            Exit 0
        }
        Else{Write-host "Something went wrong please contact your Administrator"
            Exit 1
        }
        
    }
    Catch{
        $error[0] | Format-List -Force
        Exit 1
    }

#EOF 
