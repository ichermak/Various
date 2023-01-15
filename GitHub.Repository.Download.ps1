function Invoke-GithubDownload {
    <#
        .SYNOPSIS
        Download content from GitHub.

        .DESCRIPTION
        Download content from GitHub.

        .PARAMETER Owner
        Name of the repository owner.

        .PARAMETER Repo
        Repository name.

        .PARAMETER Path
        Path under the repository.

        .PARAMETER Destination
        Folder path destination.

        .PARAMETER Log
        When specified, a log file is generated under "<Location of the current script>\Logs\".
        
        .EXAMPLE
        Invoke-GithubDownload -Owner = 'cubewise-code' -Repo = 'bedrock' -Path = 'main' -Destination = 'C:\Users\ichermak\Downloads\Bedrock -Log

        .NOTES
        Author: Ifthen CHERMAK
        Version 0.0.1 (2020/10/09) : Initial version.
    #>
    Param(
        [Parameter(Mandatory = $False)] [String]$Owner = 'cubewise-code',
        [Parameter(Mandatory = $False)] [String]$Repo = 'bedrock',
        [Parameter(Mandatory = $False)] [String]$Path = 'main',
        [Parameter(Mandatory = $False)] [String]$Destination = 'C:\Users\ichermak\Downloads\Bedrock',
        [parameter(Mandatory = $False)] [Switch]$Log
    )

    If ($Log) {
        $LogFilePath = "$PSScriptRoot\Logs\" + $MyInvocation.MyCommand.Name + '_' + (Get-Date -UFormat '%Y%m%d').ToString() + (Get-Date -Format '%H%m%s').ToString() + '.log'
        Start-Transcript -Path $LogFilePath 
    }

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
        $Directories | Foreach-Object {Invoke-GithubDownload -Owner $Owner -Repo $Repo -Path $_.path -Destination $($Destination + '\' + $_.name)}
    }
    Catch {
        Write-Error "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
    }

    If ($Log) {
        Stop-Transcript
    }
}
