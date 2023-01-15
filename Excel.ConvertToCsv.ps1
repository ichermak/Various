$excelPath = 'C:\Applications\Powershell\Tests\Test.xlsx'
$csvPath = 'C:\Applications\Powershell\Tests\Test.csv'
$startRow = 5
$delimiter = ';'
$encoding = 'ascii'

Install-Module -Name ImportExcel
$excel = Import-Excel -Path $excelPath -NoHeader -StartRow $startRow -DataOnly 
$excel | Export-Csv -Path $csvPath -delimiter $delimiter -UseQuotes AsNeeded -Encoding $encoding