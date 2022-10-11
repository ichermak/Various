# Variables
$Tm1RestApiVersion = 'v1'
$Tm1WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$Tm1User = 'Admin'
$Tm1Password = 'Apple'
$Tm1AdminHost = 'localhost'
$Tm1Protocol = 'https'
$Tm1HttpPortNumber = '5898'
$Destination = "$PSScriptRoot\" + $MyInvocation.MyCommand.Name + '.csv'

# Functions
function Export-PublicContent {
    param (
        [parameter(Mandatory=$True)] $ServerName,
        [parameter(Mandatory=$True)] $Content,
        [parameter(Mandatory=$True)] $ContentPath,
        [parameter(Mandatory=$True)] $Destination
    )

    $Header = 'Server.Name' + ';' + 'Public/Private' + ';' + 'Content.Path' + ';' + 'Content.Odata.type' + ';' + 'Content.ID' + ';' + 'Content.Name' + ';' + 'Content.Document.ID' + ';' + 'Content.Document.Name' + ';' + 'Content.Document.Size (Octet)' + ';' + 'Content.Document.LastUpdated'

    foreach ($SubContent in $Content.Contents) {
        $SubContentPath = $ContentPath + '\' + $SubContent.Name
        if ($SubContent.'@odata.type' -like '#ibm.tm1.api.*.Folder') {
            Export-Content -ServerName $ServerName -Content $SubContent -ContentPath $SubContentPath -Destination $Destination
        }
        elseif ($SubContent.'@odata.type' -like '#ibm.tm1.api.*.DocumentReference') {
            If(-Not (Test-Path -Path $Destination)) {
                $Header >> $Destination
            }

            If(-not (Get-Content -Path $Destination)) {
                $Header >> $Destination
            }

            $ServerName + ';' + 'Public' + ';' + $SubContentPath + ';' + $SubContent.'@odata.type' + ';' + $SubContent.ID + ';' + $SubContent.Name + ';' + $SubContent.Document.ID + ';' + $SubContent.Document.Name + ';' + $SubContent.Document.Size + ';' + $SubContent.Document.LastUpdated >> $Destination
        }
    }
}

function Export-PrivateContent {
    param (
        [parameter(Mandatory=$True)] $ServerName,
        [parameter(Mandatory=$True)] $Content,
        [parameter(Mandatory=$True)] $ContentPath,
        [parameter(Mandatory=$True)] $Destination
    )

    $Header = 'Server.Name' + ';' + 'Public/Private' + ';' + 'Content.Path' + ';' + 'Content.Odata.type' + ';' + 'Content.ID' + ';' + 'Content.Name' + ';' + 'Content.Document.ID' + ';' + 'Content.Document.Name' + ';' + 'Content.Document.Size (Octet)' + ';' + 'Content.Document.LastUpdated'

    foreach ($SubContent in $Content.PrivateContents) {
        $SubContentPath = $ContentPath + '\' + $SubContent.Name
        if ($SubContent.'@odata.type' -like '#ibm.tm1.api.*.Folder') {
            Export-Content -ServerName $ServerName -Content $SubContent -ContentPath $SubContentPath -Destination $Destination
        }
        elseif ($SubContent.'@odata.type' -like '#ibm.tm1.api.*.DocumentReference') {
            If(-Not (Test-Path -Path $Destination)) {
                $Header >> $Destination
            }

            If(-not (Get-Content -Path $Destination)) {
                $Header >> $Destination
            }

            $ServerName + ';' + 'Private' + ';' + $SubContentPath + ';' + $SubContent.'@odata.type' + ';' + $SubContent.ID + ';' + $SubContent.Name + ';' + $SubContent.Document.ID + ';' + $SubContent.Document.Name + ';' + $SubContent.Document.Size + ';' + $SubContent.Document.LastUpdated >> $Destination
        }
    }
}

# To disregard the certificate
if ($PSEdition -ne 'Core') {
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
}

# Initialize destination
if (Test-Path -Path $Destination) {
    Remove-Item -Path $Destination
}

# Loop through servers
$Tm1RestApiUrl = $Tm1Protocol + "://" + $Tm1AdminHost + ":" + $Tm1HttpPortNumber + "/api"
$Tm1RestRequestUrl = $Tm1RestApiUrl + '/' + $Tm1RestApiVersion + '/' + 'Servers'
$Tm1RestRequestUrl = [System.Web.HttpUtility]::UrlPathEncode($Tm1RestRequestUrl)
if ($PSEdition -ne 'Core') {
    $Tm1Servers = Invoke-RestMethod -WebSession $Tm1WebSession -Method 'GET' -Headers $Tm1Headers -uri $Tm1RestRequestUrl
} 
else {
    $Tm1Servers = Invoke-RestMethod -WebSession $Tm1WebSession -SkipCertificateCheck -Method 'GET' -Headers $Tm1Headers -uri $Tm1RestRequestUrl
}

$Tm1Headers = @{
    "Authorization" = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Tm1User):$($Tm1Password)")); 
    "Content-Type"  = "application/json"
}

foreach ($Tm1Server in $Tm1Servers.value) {
    $Tm1RestApiUrl = $Tm1Server.Host + "/api"
    
    # Establish the connection
    $Tm1RestRequestUrl = $Tm1RestApiUrl + '/' + $Tm1RestApiVersion + '/' + 'ActiveSession'
    $Tm1RestRequestUrl = [System.Web.HttpUtility]::UrlPathEncode($Tm1RestRequestUrl)
    if ($PSEdition -ne 'Core') {
        $Tm1Login = Invoke-RestMethod -WebSession $Tm1WebSession -Method 'GET' -Headers $Tm1Headers -uri $Tm1RestRequestUrl
    } 
    else {
        $Tm1Login = Invoke-RestMethod -WebSession $Tm1WebSession -SkipCertificateCheck -Method 'GET' -Headers $Tm1Headers -uri $Tm1RestRequestUrl
    }

    # Get applications
    $Tm1RestMethod = 'GET'
    $Tm1RestRequest = 'Contents(''Applications'')?$expand=tm1.Folder/Contents($expand=tm1.Folder/Contents($expand=tm1.Folder/Contents($expand=tm1.Folder/Contents($expand=tm1.Folder/Contents($expand=tm1.Folder/Contents,tm1.DocumentReference/Document)))))'
    $Tm1RestRequestUrl = $Tm1RestApiUrl + '/' + $Tm1RestApiVersion + '/' + $Tm1RestRequest
    $Tm1RestRequestUrl = [System.Web.HttpUtility]::UrlPathEncode($Tm1RestRequestUrl)

    if ($PSEdition -ne 'Core') {
        $Tm1PublicApplications = Invoke-RestMethod -WebSession $Tm1WebSession -Method $Tm1RestMethod -uri $Tm1RestRequestUrl
    }
    else {
        $Tm1PublicApplications = Invoke-RestMethod -WebSession $Tm1WebSession -SkipCertificateCheck -Method $Tm1RestMethod -uri $Tm1RestRequestUrl
    }

    Export-PublicContent -ServerName $Tm1Server.Name -Content $Tm1PublicApplications -ContentPath $Tm1PublicApplications.Name -Destination $Destination

    $Tm1RestRequest = 'Contents(''Applications'')?$expand=tm1.Folder/PrivateContents($expand=tm1.Folder/PrivateContents($expand=tm1.Folder/PrivateContents($expand=tm1.Folder/PrivateContents($expand=tm1.Folder/PrivateContents($expand=tm1.Folder/PrivateContents,tm1.DocumentReference/Document)))))'
    $Tm1RestRequestUrl = $Tm1RestApiUrl + '/' + $Tm1RestApiVersion + '/' + $Tm1RestRequest
    $Tm1RestRequestUrl = [System.Web.HttpUtility]::UrlPathEncode($Tm1RestRequestUrl)

    if ($PSEdition -ne 'Core') {
        $Tm1PrivateApplications = Invoke-RestMethod -WebSession $Tm1WebSession -Method $Tm1RestMethod -uri $Tm1RestRequestUrl
    }
    else {
        $Tm1PrivateApplications = Invoke-RestMethod -WebSession $Tm1WebSession -SkipCertificateCheck -Method $Tm1RestMethod -uri $Tm1RestRequestUrl
    }

    Export-PrivateContent -ServerName $Tm1Server.Name -Content $Tm1PrivateApplications -ContentPath $Tm1PrivateApplications.Name -Destination $Destination

    # Logout        
    $Tm1RestRequestUrl = $Tm1RestApiUrl + '/' + 'logout'
    $Tm1RestRequestUrl = [System.Web.HttpUtility]::UrlPathEncode($Tm1RestRequestUrl)
    if ($PSEdition -ne 'Core') {
        $Tm1Logout = Invoke-RestMethod -WebSession $Tm1WebSession -Method 'GET' -uri $Tm1RestRequestUrl
    }
    else {
        $Tm1Logout = Invoke-RestMethod -WebSession $Tm1WebSession -SkipCertificateCheck -Method 'GET' -uri $Tm1RestRequestUrl
    }
}