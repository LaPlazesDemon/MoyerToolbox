# Get CPU temperature
$cpuTemperature = Get-WmiObject -Namespace "root\WMI" -Class "MSAcpi_ThermalZoneTemperature" | Select-Object -ExpandProperty "CurrentTemperature" | ForEach-Object {[Math]::Round(($_ / 10 - 273.15) * 1.8 + 32)}

# Calculate median CPU temperature
$sortedTemperatures = $cpuTemperature | Sort-Object
$count = $sortedTemperatures.Count
if ($count % 2 -eq 0) {
    $medianTemperature = ($sortedTemperatures[$count/2 - 1] + $sortedTemperatures[$count/2]) / 2
} else {
    $medianTemperature = $sortedTemperatures[($count-1)/2]
}

# Get CPU usage
$cpuUsage = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty LoadPercentage

# Get memory usage
$processes = Get-Process
$totalMemory = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
$memoryUsage = ($processes | Measure-Object -Property WorkingSet -Sum).Sum
$memoryUsagePercentage = [Math]::Round(($memoryUsage / $totalMemory) * 100)

# Get free space on C:\
$freeSpace = Get-WmiObject -Class Win32_Volume | Where-Object {$_.DriveLetter -eq "C:"} | Select-Object -ExpandProperty FreeSpace
$freeSpaceGB = [Math]::Round($freeSpace / 1GB)

# Get api data
$docsData = Invoke-RestMethod 'http://localhost:3010/api/documentcounts' -Method 'GET'
$promoData = Invoke-RestMethod 'http://localhost:3010/api/offline/promo/rules' -Method 'GET'

# Check if JWT generated
try {
$result = Invoke-RestMethod -Uri 'http://localhost:9512/v1/api/getConfigProperties/jwt' -Method 'GET'
    $jwtstatus = $true
} catch {
    $jwtstatus = $false
}

#check if setup completed
$deviceSetup = (Invoked-RestMethod -Uri 'http://localhost:9510/v1/api/auth/deviceSetupStatus' -Method 'GET').data.isSetupComplete

$fileExists = Test-Path "C:\7POS\*.jks"
if ($fileExists) {
    $jks = $true
} else {
    $jks = $false
}

$fileExists = Test-Path "C:\7POS\*.yml.enc"
if ($fileExists) {
    $yml = $true
} else {
    $yml = $false
}

$partialProcessName = "localdataservice"
$processRunning = (Get-Process | Where-Object {$_.ProcessName -like "*$partialProcessName*"}) -ne $null
if ($processRunning) {
    $localdataservice = $true
} else {
    $localdataservice = $false
}

$partialProcessName = "7posapp"
$processRunning = (Get-Process | Where-Object {$_.ProcessName -like "*$partialProcessName*"}) -ne $null
if ($processRunning) {
    $7posapp = $true
} else {
    $7posapp = $false
}

# Get network adapter information
$networkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress -ne $null} | Select-Object -Property IPAddress, DefaultIPGateway, DNSDomain, MACAddress
$networkAdapters = $networkAdapters | ForEach-Object {
    $result = [ordered]@{}
    $result['IP Address'] = $_.IPAddress -join ","
    $result['Default Gateway'] = $_.DefaultIPGateway -join ","
    $result['DNS Domain'] = $_.DNSDomain
    $result['MAC Address'] = $_.MACAddress
    [pscustomobject]$result
}

    $Timezone = (Get-WmiObject -Class win32_timezone) -replace '(?:\\.+\=\")(\w)(?:.+)', '$1ST'
    $os = Get-WmiObject Win32_OperatingSystem
    $BootTime = $OS.converttodatetime($OS.LastBootUpTime)
    $Uptime = New-TimeSpan (Get-Date $BootTime)
    $Uptime_Days = [string]$Uptime.days + ' Days'


$PosName = hostname
# Output results
[PSCustomObject]@{
    'Healthcheck for ' = "$PosName`r`n"
    'Time Zone' = $Timezone 
    'Last Reboot' = $BootTime
    'UpTime' = $Uptime_Days
    'CPU Temperature' = "${medianTemperature}F"
    'CPU Usage' = "${cpuUsage}%"
    'Memory Usage' = "${memoryUsagePercentage}%"
    'C:\ Free Space' = "${freeSpaceGB}GB"
    'IP Address' = $networkAdapters.'IP Address'
    'Default Gateway' = $networkAdapters.'Default Gateway'
    'DNS Domain' = $networkAdapters.'DNS Domain'
    'MAC' = $networkAdapters.'MAC Address'
    'Item count' = $docsData.items
    'User count' = $docsData.users
    'Promo count' = $promoData.totalcount
    'Device Setup Completed' = $deviceSetup
    'JWT Generated' = $jwtstatus
    'jks File generated' = $jks
    'yml File generated' = $yml
    '7POS App Running' = $7posapp
    'Local Data Service Running' = $localdataservice
}