<#
Script that sets an Attributes(Tag) value on every VirtualMachine the Account provided can see. 
- Recommended to use a Snow Commander Superuser account
- Attribute must exist in Commander before running
- Tested on 8.10.x
#>

$vCommanderServer = "localhost"  #resolvable DNS name of the server for example "commander.domain.local"
$Attribname = "SnapshotPolicy"   #Attribute to Update
$AttribValue = "Yes"             #Attribute Value to set
$BypassCert = "Yes"              #Bypass Cert for Unsigned Certificate on the Commander Server

$DebugPreference="Continue"
$ErrorActionPreference = "Stop"

#Prompt for Credential
    $Credential = Get-Credential -Message "Please enter a Superuser credential for Snow Commander to continue"
    $user = $credential.GetNetworkCredential().UserName
    $Pass = $Credential.GetNetworkCredential().Password

#Check All Variables Present
    if(!($vCommanderServer) -or !($user) -or !($pass) -or !($Attribname) -or !($AttribValue)  -or !($BypassCert)){
        Write-error "Please provide all required input variables to execute this workflow"
        Exit 1} 

#GetToken
    $Token = $null
    $TokenURL = "https://$vCommanderServer/rest/v3/tokens"
    $TokenBody = "{
                ""username"": ""$user"",
                ""password"": ""$pass"" 
                }"
    $TokenResult = Invoke-RestMethod -Method POST $TokenURL -Body $TokenBody -ContentType 'application/json'
    $Token = $TokenResult.token
    $AuthHeader = @{"Authorization"= "Bearer $Token"}
        
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


#Get VMs loop through the vm's 500 at a time 
    $Page = 1
    $Maxcount = 500

Do {$VMendpoint = "https://$vCommanderServer"+"/rest/v3/virtual-machines?page_size=$Maxcount&page_number=$Page"
    #for VMware only:  $VMendpoint = "https://$vCommanderServer"+"/rest/v3/virtual-machines?page_size=1000&page_number=$Page&filter=(attribute:$Attribname -ne $AttribValue) -and (cloud_account_type -eq VMWARE_VCENTER)
        $VMresults = Invoke-Restmethod -Method GET -Uri $VMendpoint -Headers $AuthHeader
        $Count = $VMresults.items.count
        Write-host "Page $Page with $count VM's"
        $Page = [int]$Page += 1

    #Refresh JWT Token 
        $refreshURL = "https://$vCommanderServer/rest/v3/tokens/refresh"
        $refreshBody = "{ ""token"": ""$token""}"
        $refreshResult = Invoke-RestMethod -Method POST $refreshURL -Body $refreshBody -ContentType 'application/json'
        $Token = $refreshResult.token
        $AuthHeader = @{"Authorization"= "Bearer $Token"}

    #loop through VM's by ID
        $VMObjects = $null
        $VMObjects = $VMresults.items
        $JSONbody = "{ 
            ""name"":""$Attribname"",
            ""value"":""$AttribValue"" 
            }"
       
        $VMObjects | ForEach-Object{
                $VMid = $currentAttribs = $vmname = $null
                $VMID = $_.id
                $VMName = $_.name
                Write-Debug "Getting attributes on $vmname with id $VMid"
                $AttribURI = "https://$vCommanderServer/rest/v3/virtual-machines/$VMid/attributes"
                $SetAttributes = Invoke-RestMethod -Method GET -Uri $AttribURI -Headers $AuthHeader -ContentType "application/json" 
                $currentAttribs  = $SetAttributes.items.name
                if($currentAttribs -contains "$Attribname"){
                    Write-Debug "Updating $Attribname on $vmname with id $VMid"
                    $PatchAttribURI = "https://$vCommanderServer/rest/v3/virtual-machines/$VMid/attributes/$Attribname"
                    $patchbody = "{""value"":""$AttribValue""}"
                    $PatchVMAttribute = Invoke-RestMethod -Method Patch -Uri $PatchAttribURI -Headers $AuthHeader -Body $patchbody -ContentType "application/json" 
                }
                Elseif($currentAttribs -notcontains "$Attribname"){
                    Write-Debug "Setting $Attribname on $vmname with id $VMid"
                    $VMAttribute = Invoke-RestMethod -Method POST -Uri $AttribURI -Headers $AuthHeader -Body $JSONbody -ContentType "application/json" 
                }
                Else{Write-host "No match for $vmname and $Attribname - Something went Wrong"
                }

        #Refresh JWT Token 
            $refreshURL = "https://$vCommanderServer/rest/v3/tokens/refresh"
            $refreshBody = "{ ""token"": ""$token""}"
            $refreshResult = Invoke-RestMethod -Method POST $refreshURL -Body $refreshBody -ContentType 'application/json'
            $Token = $refreshResult.token
            $AuthHeader = @{"Authorization"= "Bearer $Token"}
        }
}
    Until($Count -eq 0)
     
 
