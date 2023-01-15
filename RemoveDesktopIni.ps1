$DesktopIniFiles = get-childitem -Path "C:\" -Filter "desktop.ini" -File -Recurse
foreach ($DesktopIniFile in $DesktopIniFiles) {
    Remove-Item -Path $DesktopIniFile.FullName
}