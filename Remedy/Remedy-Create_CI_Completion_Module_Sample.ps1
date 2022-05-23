<#
Sample Module to Create a CI in Remedy as part of a VM Completion Workflow.

Requirements: 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
#>

$RemedyAddress = "#{inputVariable['remedy_address']}"
$Username = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value; #Credential
$Password = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$BypassCert = "#{inputVariable['bypass_Cert']}"    #to bypass an unsigned SSL cert on the Target

#Workorder Variables
$ShortDescription = "Created by Snow Commander RequestID - #{request.id}"
$CIName = "#{target.deployedName}"
$DataSetId = "BMC.ASSET"
$NameSpace = "BMC.CORE"
$Class = "BMC_ComputerSystem"
$Company = "#{request.requester.organization.name}"
$OwnerName = "#{request.requester.email}"

#$DebugPreference="Continue"
$ErrorActionPreference = "Stop"

if (!($RemedyAddress) -or !($UserName) -or !($Password)) {
    Write-error "Please provide Remedy Login Information"
    Exit 1
}
if (!($ShortDescription) -or !($CiName) -or !($DataSetId) -or !($NameSpace) -or !($Class) -or !($OwnerName) -or !($Company)) {
    Write-error "Please provide Remedy Login Information"
    Exit 1
}

#Bypass unsigned SSL cert for phpipam
if ($BypassCert -eq "Yes") {
    Write-host "- Ignoring invalid Certificate" -ForegroundColor Green

    # Create a compilation environment
    $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $Provider.CreateCompiler()
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
    $AuthHeader = @{
        Authorization = "AR-JWT $($Token)"
    }

#Create CI
        $CIUri = "https://$($RemedyAddress)/api/cmdb/v1/instance/$($DataSetId)/$($NameSpace)/$($Class)"
    
        $Cijsonbody = "{""attributes"": {
                        ""Name"": ""$CIName"",
                        ""ShortDescription"": ""$ShortDescription"",
                        ""DatasetId"": ""$DataSetId"", 
                        ""Company"": ""$Company"",
                        ""OwnerName"": ""$Ownername""
                        }
        }"
        $Cijsonbody = ConvertFrom-Json $Cijsonbody| ConvertTo-Json 
        $CIResult = Invoke-WebRequest -uri $CiUri -Method POST -ContentType 'application/json' -Headers $AuthHeader -Body $Cijsonbody
        $CreatedCiURI = $CIResult.Headers.Location 
        $CIId = $CreatedCiURI -split('/')[-1] | Select-Object -last 1


        Write-host "Created CI identifier is $CIId"
        $CreatedCI = Invoke-RestMethod -uri "$CreatedCiURI" -Method Get -ContentType 'application/json' -Headers $AuthHeader
        $CIData = $CreatedCI.attributes
