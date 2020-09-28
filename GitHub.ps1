function Invoke-GithubDownload {
Param(
    [Parameter(Mandatory = $False)] [String]$Owner = 'cubewise-code',
    [Parameter(Mandatory = $False)] [String]$Repo = 'bedrock',
    [Parameter(Mandatory = $False)] [String]$Path = 'main',
    [Parameter(Mandatory = $False)] [String]$Destination = 'C:\Users\ichermak\Downloads\Bedrock'
    )

    Try {

        # Constant variables
        $GitApiRootUrl = "https://api.github.com"

        # Create a destination if it does not exist
        If (-not (Test-Path $Destination)) {
            New-Item -Path $Destination -ItemType Directory -ErrorAction Stop
        }

        # Get list of objects from GitHub repository
        $GitApiUrl = "$GitApiRootUrl/repos/$Owner/$Repo/contents/$Path"
        $Objects = (Invoke-WebRequest -Uri $GitApiUrl).Content | ConvertFrom-Json
        
        # Download files 
        $DownloadUrls = $Objects | Where {$_.type -eq "file"} | Select -exp download_url
        Foreach ($DownloadUrl in $DownloadUrls) {
            $File = [System.Web.HttpUtility]::UrlDecode($DownloadUrl)
            $OutFile = Join-Path $Destination (Split-Path $File -Leaf)
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $OutFile -ErrorAction Stop -Verbose
        }

        # Browse descendant directories
        $Directories = $Objects | Where {$_.type -eq "dir"}
        $Directories | Foreach-Object { 
            Invoke-GithubDownload -Owner $Owner -Repo $Repo -Path $_.path -Destination $($Destination + '\' + $_.name)
        }
    }
    Catch {
        Write-Error "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
        Break
    }
}