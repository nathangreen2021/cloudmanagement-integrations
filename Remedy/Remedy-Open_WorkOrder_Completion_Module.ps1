<#
Sample Module to Create a Workorder in Remedy as part of a VM Completion Workflow.

Requirements: 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
#>

$RemedyAddress = "#{inputVariable['remedy_address']}"
$Username = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value; #Credential
$Password = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$BypassCert = "#{inputVariable['bypass_Cert']}"    #to bypass an unsigned SSL cert on the Target

#Workorder Variables
$Description = "Created by Snow Commander"
$Firstname = "XXXX"
$Lastname = "XXXX"
$CustomerFirstName = "XXXX"
$CustomerLastName = "XXXX"
$Summary = "Commander RequestID - #{request.id}"
$Status = "#{inputVariable['workOrderStatus']}" 
$Company = "#{request.requester.organization.name}"
$CustomerCompany = "#{request.requester.organization.name}"
$Location = "#{request.requester.organization.name}"

#$DebugPreference="Continue"
$ErrorActionPreference = "Stop"

if (!($RemedyAddress) -or !($WorkorderID) -or !($UserName) -or !($Password)) {
    Write-error "Please provide Remedy Login Information"
    Exit 1
}
if (!($Description) -or !($Firstname) -or !($Lastname) -or !($CustomerFirstName) -or !($CustomerLastName) -or !($Summary) -or !($Status) -or !($Company) -or !($CustomerCompany) -or !($Location)) {
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

#Create Workorder
        $WoclUri = "https://$($RemedyAddress)/api/arsys/v1/entry/WOI:WorkOrderInterface_Create/"
        $Wojsonbody = "{""values"": {
                        ""Detailed Description"": ""$Description"",
                        ""z1D_Action"": ""CREATE"",
                        ""First Name"": ""$firstname"",
                        ""Last Name"": ""$lastname"",
                        ""Customer First Name"": ""$CustomerFirstName"",
                        ""Customer Last Name"": ""$CustomerLastName"",
                        ""Summary"": ""$Summary"",
                        ""Status"": ""$Status"",
                        ""Company"": ""$Company"",
                        ""Customer Company"": ""$CustomerCompany"",
                        ""Location Company"": ""$Location""
                        }
        }"
        $Wojsonbody = ConvertFrom-Json $Wojsonbody| ConvertTo-Json 
        Invoke-RestMethod -uri $WoclUri -Method POST -ContentType 'application/json' -Headers $AuthHeader -Body $Wojsonbody

    
