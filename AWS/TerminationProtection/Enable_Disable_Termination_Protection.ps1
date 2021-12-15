<#
Script to Enable/Disable Termination protection on an AWS EC2 instance
* Requires PS modules "AWSPowerShell.netcore" on the Commander server. 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
#>


#AWS Information
$AccessKey = (Get-Item Env:AWS_ACCESS_KEY_ID).value
$SecretKey = (Get-Item Env:AWS_SECRET_ACCESS_KEY).value
$Instance = '#{target.remoteId}' 
$Region = '#{target.region.name}' 
$Action = "#{inputVariable['TermProValue']}" #Action Value {Enable:Disable}

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
    $InstanceTermination = (Get-EC2InstanceAttribute -InstanceId $Instance -Region $Region -Attribute DisableApiTermination).DisableApiTermination

#Enable Instance Ternination
    Try{
        IF($InstanceTermination -eq $False -and $Action -eq "Enabled"){
             Edit-EC2InstanceAttribute -InstanceId $Instance -DisableApiTermination $true -Region $Region
             #Small wait just to be sure the api updates
             Start-sleep $APIwait 
             $TermValue = (Get-EC2InstanceAttribute -InstanceId $Instance -Region $Region -Attribute DisableApiTermination).DisableApiTermination
                Switch($TermValue)
                    {
                    $true {$TermValue = "Enabled"}
                    $False {$TermValue = "Disabled"}
                    }
          Write-Host "Termination Protection on instance $Instance has been set to $TermValue" -ForegroundColor Green
        }

#Disable Instance Ternination
         ElseIF ($InstanceTermination -eq $True -and $Action -eq "Disable"){
             Edit-EC2InstanceAttribute -InstanceId $Instance -DisableApiTermination $false -Region $Region
             #Small wait just to be sure the api updates
             Start-sleep $APIwait 
             $TermValue = (Get-EC2InstanceAttribute -InstanceId $Instance -Region $Region -Attribute DisableApiTermination).DisableApiTermination
                Switch($TermValue)
                    {
                    $true {$TermValue = "Enabled"}
                    $False {$TermValue = "Disabled"}
                    }
          Write-Host "Termination Protection on instance $Instance has been set to $TermValue" -ForegroundColor Green
        }
        Else{
            Switch($TermValue)
                    {
                    $true {$TermValue = "Enabled"}
                    $False {$TermValue = "Disabled"}
                    }
            Write-Host "Termination Protection on instance $Instance Is already set to $TermValue" -ForegroundColor Green
        }
    }
    Catch{
        $error[0] | Format-List -Force
        Exit 1;
    }

#EOF 