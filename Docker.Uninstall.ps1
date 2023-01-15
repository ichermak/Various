<#
    .SYNOPSIS
    Uninstall docker.

    .DESCRIPTION
    Uninstall docker.

    .PARAMETER Log
    When specified, a log file is generated under "<Location of the current script>\Logs\".
    
    .EXAMPLE
    .\Docker.Uninstall.ps1 -Log

    .NOTES
    Author: Ifthen CHERMAK
    Version 0.0.1 (2020/10/09) : Initial version.
#>
Param (
    [parameter(Mandatory = $False)] [Switch]$Log
)

If ($Log) {
    $LogFilePath = "$PSScriptRoot\Logs\" + $MyInvocation.MyCommand.Name + '_' + (Get-Date -UFormat '%Y%m%d').ToString() + (Get-Date -Format '%H%m%s').ToString() + '.log'
    Start-Transcript -Path $LogFilePath 
}

Try {
    # Préparer votre système à la suppression de Docker
    # ====================================================

    # Leave swarm mode (this will automatically stop and remove services and overlay networks)
    docker swarm leave --force

    # Stop all running containers
    # ====================================================
    docker ps --quiet | ForEach-Object {docker stop $_}
    docker system prune --volumes --all

    # Désinstallation de Docker
    # ====================================================
    $DockerMsftProvider = Get-PackageProvider -Name *Docker*
    Uninstall-Package -Name docker -ProviderName $DockerMsftProvider
    Uninstall-Module -Name $DockerMsftProvider

    # Nettoyer les données et les composants système Docker
    # ====================================================
    Get-HNSNetwork | Remove-HNSNetwork
    Get-ContainerNetwork | Remove-ContainerNetwork
    Remove-Item "C:\Program Files\Docker" -Recurse -Force
    Remove-Item "C:\ProgramData\Docker" -Recurse -Force
}
Catch {
    Write-Error "$($_.Exception.Message)`n$($_.ErrorDetails.Message)"
}

If ($Log) {
    Stop-Transcript
}