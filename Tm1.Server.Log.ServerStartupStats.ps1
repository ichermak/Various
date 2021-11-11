<#
    .SYNOPSIS
    Extracts server startup statistics from tm1server.log to a csv file.

    .DESCRIPTION
    Extracts server startup statistics from tm1server.log to a csv file.

    .PARAMETER ServerLogPath
    Path to the log file or the log directory of the TM1 server.

    .PARAMETER Destination
    Destination path for the output file.

    .PARAMETER Log
    When specified, a log file is generated under "<Location of the current script>\Logs\".
    
    .EXAMPLE
    .\Tm1.Server.Log.ServerStartupStats.ps1 -ServerLogPath "C:\Applications\Tm1\24retail\Log" -Destination "C:\Applications\Powershell" -Log

    .NOTES
    Author: Ifthen CHERMAK
    Version 0.0.1 (2021/10/24): Initial version.
#>

param (
    [parameter(Mandatory = $True)] [String]$ServerLogPath,
    [parameter(Mandatory = $False)] [String]$Destination,
    [parameter(Mandatory = $False)] [Switch]$Log
)

$ErrorActionPreference = "Continue"

if ($Log) {
    $logFilePath = "$PSScriptRoot\Logs\" + $MyInvocation.MyCommand.Name + '_' + (Get-Date -UFormat '%Y%m%d').ToString() + (Get-Date -Format '%H%m%s').ToString() + '.log'
    Start-Transcript -Path $logFilePath 
}

# Parameter default values
if (-Not $Destination) {
    $Destination = $PSScriptRoot
}

# Variables
$pathSeparator = "\"

if (-Not($ServerLogPath.EndsWith("tm1server.log"))) {
    if (-Not($ServerLogPath.EndsWith($pathSeparator))) {
        $ServerLogPath = "$ServerLogPath\"
    }
    $ServerLogPath = $ServerLogPath + "tm1server.log"
}

if (-Not($Destination.EndsWith($pathSeparator))) {
    $Destination = "$Destination\"
}

$destinationPath = $Destination + $MyInvocation.MyCommand.Name + '.csv'
$prefix = "TM1 Server is ready, elapsed time"
$suffix = "seconds"
$tempCollection = @()

# Operations
$rows = ((Get-Content -Path $ServerLogPath -Raw) -replace '(?<!\x0d)\x0a','').Split("`r`n")
foreach ($row in $rows) {
    If($row -like "*$prefix*") {
        $tempObject = New-Object -TypeName PSObject
        $columns = $row.Split("   ")
        $columnIndex = 1
        foreach ($column in $columns) {
            If($column -like "*$prefix*") {
                $column = $column -Replace $prefix, "" -Replace $suffix, ""
            }
            $colName = "Column $columnIndex"
            $tempObject | Add-Member -MemberType NoteProperty -Name $colName -Value $column.Trim()
            $columnIndex += 1
        }
        $tempCollection += $tempObject
    }
}  
$tempCollection | Export-Csv -Path $destinationPath -UseCulture -UseQuotes AsNeeded -Encoding 'utf8' -Force

if ($Log) {
    Stop-Transcript
}