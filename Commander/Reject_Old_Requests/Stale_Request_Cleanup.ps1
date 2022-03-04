<#
Designed to be run as a schedualed workflow in Commander daily. 
This script finds requests that are older than X days and rejects them after a configurable time.
#> 

$CommanderServer = "#{inputVariable['CommanderBaseURL']}"
$user = (Get-Item Env:SELECTED_CREDENTIALS_USERNAME ).value;
$pass = (Get-Item Env:SELECTED_CREDENTIALS_PASSWORD).value;
$BypassCert = "#{inputVariable['bypass_Cert']}" 
$CleanupAge = "#{inputVariable['CleanupAge']}"      # Days
$Comments = "Automatic cleanup rejecting request as it's been running for more than $Cleanupage days" 



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

#GetToken
    $Token = $null
    $TokenURL = "https://$CommanderServer/rest/v3/tokens"
    $TokenBody = "{
                ""username"": ""$user"",
                ""password"": ""$pass"" 
                }"
    $TokenResult = Invoke-RestMethod -Method POST $TokenURL -Body $TokenBody -ContentType 'application/json'
    $Token = $TokenResult.token
    $AuthHeader = @{"Authorization"= "Bearer $Token"}

#Create Timespan
    $ts = new-Timespan -Days $CleanupAge
    $time = ((Get-Date).AddDays(-$ts.Days)).tostring(“yyyy-MM-dd”)

#Get VMs with Attrib setloop through requests 100 at a time 
    $Page = 1
    $Maxcount = 100
    $Rejectbody = "{ ""comment"":""$Comments""}"

Do {$RequestsEnspoint = "https://$CommanderServer"+"/rest/v3/service-requests?page_size=$Maxcount&filter=(date_submitted -lt '$time') -and (state -ne COMPLETED) -and  (state -ne REJECTED)"
        $requests = Invoke-Restmethod -Method GET -Uri $RequestsEnspoint -Headers $AuthHeader -ContentType 'application/json'
        $Count = $requests.items.count
        $Page = [int]$Page += 1
        Write-host "Page $Page with $count VM's"

    #loop through Requests by ID
        $ReqIDs = $requests.items
       
        $ReqIDs | ForEach-Object{
            $id = $name = $RejectURI = $null
            $id = $_.id
            $name = $_.name
            Write-Debug "Processing RequestID $id"
            $RejectURI = "https://$CommanderServer/rest/v3/service-requests/$id/reject"   
            Try{
                $RejectResult = Invoke-Restmethod -Method POST -Uri $RejectURI -Body $Rejectbody -Headers $AuthHeader -ContentType 'application/json'
                }
                Catch{
                    $Exception = "$_"
                    Write-Host "Failed to reject request $id, Please reject the request Manually"
                    Write-Host $Exception  
                }    
       #Refresh JWT Token 
            $refreshURL = "https://$CommanderServer/rest/v3/tokens/refresh"
            $refreshBody = "{ ""token"": ""$token""}"
            $refreshResult = Invoke-RestMethod -Method POST $refreshURL -Body $refreshBody -ContentType 'application/json'
            $Token = $refreshResult.token
            $AuthHeader = @{"Authorization"= "Bearer $Token"}                   
       }
}
    Until($Count -eq 0) 
