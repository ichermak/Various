<#
    .SYNOPSIS
    Clear all docker containers.

    .DESCRIPTION
    Clear all docker containers.

    .PARAMETER DockerCiZapPath
    Path to "docker-ci-zap.exe".

    .PARAMETER DockerFilesLocation
    Docker files folder path.
    
    .PARAMETER Log
    When specified, a log file is generated under "<Location of the current script>\Logs\".
    
    .EXAMPLE
    .\Docker.Containers.Clear.ps1 -DockerCiZapPath = 'C:\Program Files\docker-ci-zap\docker-ci-zap.exe' -DockerFilesLocation = 'C:\ProgramData\docker' -Log

    .NOTES
    Author: Ifthen CHERMAK
    Version 0.0.1 (2020/10/09) : Initial version.
#>
Param (
    [parameter(Mandatory=$False)] [String]$DockerCiZapPath = 'C:\Program Files\docker-ci-zap\docker-ci-zap.exe',
    [parameter(Mandatory=$False)] [String]$DockerFilesLocation = 'C:\ProgramData\docker',
    [parameter(Mandatory = $False)] [Switch]$Log
)

If ($Log) {
    $LogFilePath = "$PSScriptRoot\Logs\" + $MyInvocation.MyCommand.Name + '_' + (Get-Date -UFormat '%Y%m%d').ToString() + (Get-Date -Format '%H%m%s').ToString() + '.log'
    Start-Transcript -Path $LogFilePath 
}

Try {
    # Ensure the Docker Engine service is strated
    Start-Service 'docker'

    # Stop all running containers
    docker ps -aq | ForEach-Object {docker stop $_}

    # Remove all containers
    docker ps -aq | ForEach-Object {docker rm $_}

    # Remove all images
    docker images -q | ForEach-Object {docker rmi $_}

    # Use docker-ci-zap to clear all docker files
    If (Get-Service 'docker' -ErrorAction SilentlyContinue) {
        If ((Get-Service -Name 'docker').Status -eq "Running") {
            Stop-Service 'docker'
        }
    }
    $Command = """$DockerCiZapPath"" -folder ""$DockerFilesLocation"""
    Invoke-Expression -Command:"cmd.exe /c $Command"
    If (Get-Service 'docker' -ErrorAction SilentlyContinue) {
        Start-Service 'docker'
    }
}
Catch {
    Write-Error "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
}

If ($Log) {
    Stop-Transcript
}
