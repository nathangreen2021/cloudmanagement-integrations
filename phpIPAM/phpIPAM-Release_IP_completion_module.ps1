<#
Module that Calls out to phpIPAM to release the specified address in a decommissioning workflow request.
Requirements: 
* Commander 8.6.0 or higher
* Advanced property "embotics.workflow.script.credentials" must be set to "true"
* PhpIpam 1.3.1 or greater

Note:
Your Environment maye require additional or diffrent logic depending on how phpipam has been configured. This Example assumes there is no overlapping subnets in phpIPAM
#>


$IPAddress = "#{target.ipAddress}"                                    #Address to be released
$phpipamURL = "#{inputVariable['phpIPAMBaseURL']}"                    #Phpipam Base URL
$phpIPAMUser = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value;   #Credential
$phpIPAMPass = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$phpipamAppID = "#{inputVariable['phpIPAMAppID']}"                    #AppID in svrphpipam Set to "None" for security to use password auth only not token auth. 
$BypassCert = "#{inputVariable['bypass_Cert']}"                       #to bypass an unsigned SSL cert on the phpIPAM Server

#$DebugPreference="Continue"
$ErrorActionPreference = "Stop"

#Check All Variables Present
if(!($IPAddress) -or !($phpipamURL) -or !($phpIPAMUser) -or !($phpIPAMPass) -or !($phpipamAppID) -or !($BypassCert)){
        Write-error "Please provide all required input variables to execute this workflow"
        Exit 1} 

    
#Bypass unsigned SSL cert for phpipam
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


# Building phpipam API string and invoking API
    $baseAuthURL = $phpipamURL +"/api/$phpipamAppID/user/"
    # Authenticating with phpipam APIs
    $PHPcred = 
    $authInfo = ("{0}:{1}" -f $phpIPAMUser,$phpIPAMPass)
    $authInfo = [System.Text.Encoding]::UTF8.GetBytes($authInfo)
    $authInfo = [System.Convert]::ToBase64String($authInfo)
    $headers = @{Authorization=("Basic {0}" -f $authInfo)}
    $sessionBody = '{"AuthenticationMethod": "1"}'
    $contentType = "application/json"
    Try{$iPamSessionResponse = Invoke-WebRequest -Uri $baseAuthURL -Headers $headers -Method POST -ContentType $contentType
          }Catch{Write-Host "Failed to authenticate to Ipam" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
     
#Extracting Token from the response, and adding it to the actual API
    $phpipamToken = ($iPamSessionResponse | ConvertFrom-Json).data.token
    $phpipamsessionHeader = @{"token"=$phpipamToken}

#Get Data from Specific Subnet(Gateway, netmask, dns)
    Try{$IPURL = $phpipamURL +"/api/$phpipamAppID/addresses/search/$IPAddress/"
        $IPJson = Invoke-WebRequest -Uri $IPURL -Headers $phpipamsessionHeader -Method GET -ContentType $contentType
        $IPData = $IPJson | ConvertFrom-Json
        $IPSubnetID = $IPData.data.subnetid
         }Catch{Write-Host "Failed to get existing IP data from Ipam" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
    
#Setup request body to remove DNS Entry ***Not required - Depends on implementation of PhpIpam***
 $JSONbody = 
    "{
    ""remove_dns"":""1""
    }"

#perform Remove 
    Try{$DeleteURL = $phpipamURL +"/api/$phpipamAppID/addresses/$IPAddress/"+"$IPSubnetID/"
        $Delete = Invoke-WebRequest -Uri $DeleteURL -Headers $phpipamsessionHeader -Method Delete -ContentType $contentType
        #$DeleteURL1 = $phpipamURL +"/api/$phpipamAppID/addresses/$IPAddress"
        #$Delete1 = Invoke-WebRequest -Uri $DeleteURL -Headers $phpipamsessionHeader -Body $JSONbody -Method DELETE -ContentType $contentType
        $Status = ($Delete1 | ConvertFrom-Json).message
         }Catch{Write-Host "Failed to Delete Address $IPAddress from IPAM" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
        if($Status -eq 'Address deleted'){
           Write-host $status
           Exit 0
           }
        else{Write-host "$Status"
            Exit 1
        } 
