<#
Module to change the Workorder State in Remedy as part of a VM Completion Workflow.

Requirements: 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"


#>

$RemedyAddress = "#{inputVariable['remedy_address']}"
$Username = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value;   #Credential
$Password = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$WorkorderID = "#{inputVariable['RemedyWOiD']}" 
$Status = "#{inputVariable['workOrderStatus']}"     # Status to set the work order to
$BypassCert = "#{inputVariable['bypass_Cert']}"    #to bypass an unsigned SSL cert on the Target


#$DebugPreference="Continue"
$ErrorActionPreference = "Stop"

if (!($RemedyAddress) -or !($WorkorderID) -or !($UserName) -or !($Password)) {
    Write-error "Please provide Remedy information to close the workorder"
    Exit 1
}

#Bypass unsigned SSL cert for phpipam
if ($BypassCert -eq "Yes") {
    Write-host "- Ignoring invalid Certificate" -ForegroundColor Green

    # Create a compilation environment
    $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $Compiler = $Provider.CreateCompiler()
    $Params = New-Object System.CodeDom.Compiler.CompilerParameters
    $Params.GenerateExecutable = $False
    $Params.GenerateInMemory = $True
    $Params.IncludeDebugInformation = $False
    $Params.ReferencedAssemblies.Add("System.DLL") > $null
    $TASource = @'
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
    $TAResults = $Provider.CompileAssemblyFromSource($Params, $TASource)
    $TAAssembly = $TAResults.CompiledAssembly
    $TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
    [System.Net.ServicePointManager]::CertificatePolicy = $TrustAll
}

#Get Remedy Token
    $TokenUri = "https://$RemedyAddress/api/jwt/login"
    $TokenContentType = 'application/x-www-form-urlencoded'
    $TokenBody = @{
        username = $($Username)
        password = $($Password)
    }
    $Token = Invoke-RestMethod -uri $TokenUri -Method POST -ContentType $TokenContentType -body $TokenBody

#Get Remedy WorkOrders
    $WoUri = "https://$($RemedyAddress)/api/arsys/v1/entry/WOI:WorkOrderInterface"
    $AuthHeader = @{
        Authorization = "AR-JWT $($Token)"
    }
    $WoResults = Invoke-RestMethod -uri $WoUri -Method GET -ContentType 'application/json' -Headers $AuthHeader

    $WoData = $WoResults.entries.values| Select-object "Request ID","Work Order ID", Status | where-object "Work Order ID" -eq $WorkorderID
    $WoReqID = $WoData."Request ID"


#Close Workorder if it's not in a closed state
    $woStatus = $WoData.status
    if ($woStatus -eq "$status") {
        Write-host "WorkOrder number $WorkorderID is already closed"
        Exit 0  
    }
    Elseif ($woStatus -ne "$Status") {
        Write-host "WorkOrder $WorkorderID is $woStatus Attempting to close. "
        $WoclUri = "https://$($RemedyAddress)/api/arsys/v1/entry/WOI:WorkOrderInterface/$WoReqID"
        $Wojsonbody  = "{""values"":
                            { ""Status"" : ""$status"" }
                        }"
        $Wojsonbody = ConvertFrom-Json $Wojsonbody| ConvertTo-Json 
        Invoke-RestMethod -uri $WoclUri -Method PUT -ContentType 'application/json' -Headers $AuthHeader -Body $Wojsonbody
    #Check State
        $WoResults = Invoke-RestMethod -uri $WoUri -Method GET -ContentType 'application/json' -Headers $AuthHeader
        $WoData = $WoResults.entries.values | Select-object "Request ID", "Work Order ID", Status | where-object "Work Order ID" -eq $WorkorderID
        $WoState = $WoData.Status
        if($wostate -eq $status){
            Write-host Write-host "WorkOrder $WorkorderID has been Marked as $status"
        }
        Exit 0
    }
    Else {
        Write-Error "Something went wrong looking up the status for WorkorderID $WorkorderID, Please contact your Remedy Administrator"
        Exit 1
        
    } 

 
