$tm1ServiceName = 'ichermak - izi'
$tm1ProcessId = ((Get-WmiObject Win32_Service -FIlter "Pathname like '%tm1sd%'" | ForEach-Object {$p = Get-Process -PID $_.ProcessID $p | Add-Member -MemberType NoteProperty -Name ServiceName -Value $_.Caption -PassThru} | Sort WS -Descending | Select ID, ServiceName) | Where-Object {$_.ServiceName -like "*$tm1ServiceName"}).Id
Stop-Service -Name $tm1ServiceName -Force
Stop-Process -Id $tm1ProcessId -Force

function Kill-Tree {
    Param([int]$ppid)
    Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ppid } | ForEach-Object { Kill-Tree $_.ProcessId }
    Stop-Process -Id $ppid
}