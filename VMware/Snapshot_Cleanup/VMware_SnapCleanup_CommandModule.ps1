$Snapshotage = "#{inputVariable['SnapshotAge']}"
$vCommanderServer = "#{inputVariable['CommanderBaseURL']}" 
$user = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value;
$pass = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$Attrib = "#{inputVariable['Attribute_Target']}" 
$BypassCert = "#{inputVariable['bypass_Cert']}" 

#Check All Variables Present
if(!($Snapshotage) -or !($vCommanderServer) -or !($user) -or !($pass) -or !($Attrib)){
        Write-error "Please provide all required input variables to execute this workflow"
        Exit 1} 

    $ErrorActionPreference = "Stop"
#Setup Credential
        $Credential= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$User",("$Pass" | ConvertTo-SecureString -AsPlainText -Force)  
        write-host  "Cred object created for $user"
        
#Bypass unsigned SSL for Localhost
if ($BypassCert -eq "yes"){
Write-host "- Ignoring invalid Certificate" -ForegroundColor Green

# Create a compilation environment
 $Provider=New-Object Microsoft.CSharp.CSharpCodeProvider
 $Compiler=$Provider.CreateCompiler()
 $Params=New-Object System.CodeDom.Compiler.CompilerParameters
 $Params.GenerateExecutable=$False
 $Params.GenerateInMemory=$True
 $Params.IncludeDebugInformation=$False
 $Params.ReferencedAssemblies.Add("System.DLL") > $null
 $TASource=@'
   namespace Local.ToolkitExtensions.Net.CertificatePolicy {
     public class TrustAll : System.Net.ICertificatePolicy {
       public TrustAll() { 
       }
       public bool CheckValidationResult(System.Net.ServicePoint sp,
         System.Security.Cryptography.X509Certificates.X509Certificate cert, 
         System.Net.WebRequest req, int problem) {
         return true;
       }
     }
   }
'@ 
 $TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
 $TAAssembly=$TAResults.CompiledAssembly
 $TrustAll=$TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
 [System.Net.ServicePointManager]::CertificatePolicy=$TrustAll
}
#Parse Attribute and value from Variable
    $Attribname = $Attrib.Split(":")[0]
    $AttribValue = $Attrib.Split(":")[1] 

#Get VMs with Attrib setloop throughthe vm's 1000 at a time 
    $Page = 1
    $Maxcount = 1000
    $Snapage = (Get-Date).AddDays(-$Snapshotage)

Do {$VMendpoint = "https://$vCommanderServer"+"/rest/v3/virtual-machines?page_size=1000&page_number=$Page&filter=(attribute:$Attribname -eq $AttribValue) -and (cloud_account_type -eq VMWARE_VCENTER)"
        $VMresults = Invoke-Restmethod -Method GET -Uri $VMendpoint -Credential $Credential 
        $Count = $VMresults.items.count
        Write-host "Page $Page with $count VM's"
        $Page = [int]$Page += 1

    #loop through VM's by ID
        $VMIDs = $VMresults.items.id | Sort-Object | Get-Unique
       
        ForEach($VMid in $VMIDs){
               Write-Debug "Checking VM with ID $VMid"
               # Return the list of VM snapshots
               $fullURI = "https://$vCommanderServer/webservices/services/rest/v2/vms/$vmId/snapshots"
               $vmSnapshotData = $Snapcount = $SnapIDs = $VMSnapshots = $null
               $VMSnapshots = Invoke-WebRequest -UseBasicParsing -Uri $fullURI -Method GET -Credential $Credential -ContentType "application/xml"
               [xml]$parsedsnapData = ($VMSnapshots.content).Replace('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',"") 
               $SnapIDs = $parsedsnapData.VirtualMachineSnapshotCollection.items | Select-object -ExpandProperty id
                if($SnapIDs.count){
                    $Snapcount = $SnapIDs.count
                     Write-Debug "Snapshot Count: $Snapcount"
                    }
               
                IF($Snapcount -ge 1){
                    foreach ($snapshot in ($parsedsnapData.VirtualMachineSnapshotCollection.items)){
                        $snapID = $postParams = $snapName = $snapDate = $RemoveSnapTaskResult = $RemoveTaskID = $RemoveSnapTask = $null
                        $snapName = $snapshot.name
                        $snapDate = (new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)).AddSeconds([math]::Round($snapshot.createTime/1000))
                        $snapID = $snapshot.id
                        #Write-host "Checking Snapshot ID - $SnapID"
                        if($snapDate -lt $Snapage){
                            $postParams = @{}
                            $postParams.Add("snapshotId", $snapID)
                            $DeleteURI = "https://$vCommanderServer/webservices/services/rest/v2/vms/$vmId/action/deletesnapshot"
                            $RemoveSnapTaskResult = Invoke-WebRequest -UseBasicParsing -Uri $DeleteURI -Method POST -Body $postParams -Credential $Credential -ContentType "application/x-www-form-urlencoded" 
                            [xml]$RemoveSnapTask = ($RemoveSnapTaskResult.content).Replace('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',"") 
                            
                            $RemoveTaskID = $RemoveSnapTask.TaskInfo.id
                            $VMname = $RemoveSnapTask.TaskInfo.source
                            $Snapname = $RemoveSnapTask.TaskInfo.destination
                            Write-host "Snapshot remove task $RemoveTaskID has been submitted for $VMname with snapshot: $Snapname"
                            }
                        }
                    }           
                }
            }
    Until($Count -eq 0) 
