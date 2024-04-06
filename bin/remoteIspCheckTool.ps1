Function ConvertTo-HumanReadable {
    param([double]$bytes)
    if ($bytes -ge 1GB) {
        return "{0:N2} GB" -f ($bytes / 1GB)
    } elseif ($bytes -ge 1MB) {
        return "{0:N2} MB" -f ($bytes / 1MB)
    } elseif ($bytes -ge 1KB) {
        return "{0:N2} KB" -f ($bytes / 1KB)
    } else {
        return "{0:N0} bytes" -f $bytes
    }
}

##############
## SERVICES ##
##############

$dhcpService = Get-Service -name "DHCP Server"
$cserveService = Get-Service -name "CServe"
$rtsService = Get-Service -name "RealTimeService"
$dnsService = Get-Service -name "DNS Server"

# Get the startup type lines using sc qc and store them in an array
$cserveStartupLine = (cmd /c sc qc 'cserve') | Select-String -Pattern "START_TYPE"
$dhcpStartupLine = (cmd /c sc qc 'DHCPServer') | Select-String -Pattern "START_TYPE"
$rtsStartupLine = (cmd /c sc qc 'RealTimeService') | Select-String -Pattern "START_TYPE"
$dnsStartupLine = (cmd /c sc qc 'DNS') | Select-String -Pattern "START_TYPE"

# Extract the startup type value (first character) from each line
$cserveStartupCode = $cserveStartupLine -replace '.*START_TYPE\s*:\s*(\d).*', '$1'
$dhcpStartupCode = $dhcpStartupLine -replace '.*START_TYPE\s*:\s*(\d).*', '$1'
$rtsStartupCode = $rtsStartupLine -replace '.*START_TYPE\s*:\s*(\d).*', '$1'
$dnsStartupCode = $dnsStartupLine -replace '.*START_TYPE\s*:\s*(\d).*', '$1'

# Map the startup codes to the corresponding startup types
$startupTypes = @{
    '2' = "Auto"
    '3' = "Manual"
    '4' = "Disabled"
    default = "Unknown"
}

# Get the startup type for each service
$cserveStartup = $startupTypes[$cserveStartupCode]
$dhcpStartup = $startupTypes[$dhcpStartupCode]
$rtsStartup = $startupTypes[$rtsStartupCode]
$dnsStartup = $startupTypes[$dnsStartupCode]

$servicesTable = @{
    "CServe" = @{
        "Status" = $cserveService.Status
        "Startup Type" = $cserveStartup
    }
    "DHCP Server" = @{
        "Status" = $dhcpService.Status
        "Startup Type" = $dhcpStartup
    }
    "RealTimeServices" = @{
        "Status" = $rtsService.Status
        "Startup Type" = $rtsStartup
    }
    "DNS Server" = @{
        "Status" = $dnsService.Status
        "Startup Type"  = $dnsStartup
    }
}



##############
## ISP DATA ##
##############

$hostname = hostname
$currentDate = Get-Date
$timezone = [System.TimeZone]::CurrentTimeZone.StandardName
$model = (Get-ItemProperty -Path "HKLM:\Software\NEC\HW" -Name "ProductName").ProductName
$cpuUsage = (Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average).Average

$os = Get-WmiObject -Class Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1KB)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1KB)
$usedRAM = $totalRAM - $freeRAM

$usedRAMPercent = [math]::Round(($usedRAM / $totalRAM) * 100)

$genData = @{
    Hostname = $hostname
    DateTime = $currentDate
    Timezone = $timezone
    Model = $model
    CpuUsage = $cpuUsage
    RamUsage = $usedRAMPercent
}

############
## UPTIME ##
############

$netStatsOutput = net stats srv
$uptimeLine = $netStatsOutput -match 'Statistics since'
$uptimeSince = ($uptimeLine -split 'Statistics since ')[1]
$uptime = (Get-Date) - (Get-Date $uptimeSince)
$uptimeString = "Uptime: $($uptime.Days) Days, $($uptime.Hours) Hours, $($uptime.Minutes) Minutes"



#################
## DRIVE SPACE ##
#################

$drives = Get-WmiObject -Class Win32_LogicalDisk| Where-Object { $_.DeviceID -ne 'E:' -and $_.DeviceID -ne 'A:'}

# Create an array to store the drive information
$driveInfo = @()

foreach ($drive in $drives) {
    # Convert free space to human-readable format
    $freeSpace = ConvertTo-HumanReadable -bytes $drive.FreeSpace
    $totalSpace = ConvertTo-HumanReadable -bytes $drive.Size

    # Create a custom object with the drive letter, free space, and total size
    $driveObj = [PSCustomObject]@{
        'Drive'      = $drive.DeviceID
        'Free Space' = "{0} / {1}" -f $freeSpace, $totalSpace
        'Free Bytes' = $drive.FreeSpace
    }

    # Add the custom object to the array
    $driveInfo += $driveObj
}


####################
## MEGA RAID DATA ##
####################

if (Test-Path "C:\Program Files\MegaRAID Storage Manager\startupui.bat") {
    $MegaCliRegex = '(?<Slot>Slot\snumber.+)|(?<DeviceId>^device\sid.+)|(?<Firmware>Firmware\sstate.+)|Inquiry' 
    $MegaCliPdAll = megacli -AdpAllInfo -aALL
    $DiskCount = ($MegaCliPdAll|
     Select-String '\s\sdisks\s+:')  -replace '\s+',''
    $FailedDisk = ( $MegaCliPdAll |
     Select-String 'failed\sdisk')  -replace '\s+|disks',''
    $CriticalDisk = ($MegaCliPdAll |
     Select-String 'critical') -replace '\s+|disks',''
    $DegradedDisk = ($MegaCliPdAll|
     Select-String 'degraded') -replace '\s+|disks',''
    $PhysDisk = (megacli -PDList -aall) -match $MegaCliRegex
    $PhysDisk = $PhysDisk -replace 'Firmware\sstate','State'
    $PhysDisk = $PhysDisk -replace 'device|number|\s|.*\dSS',''
    $Disk1 = "{1} {0} Serial:{3} {2}" -f  $PhysDisk[0],$PhysDisk[1],$PhysDisk[2],$PhysDisk[3]
    $Disk2 = "{1} {0} Serial:{3} {2}" -f  $PhysDisk[4],$PhysDisk[5],$PhysDisk[6],$PhysDisk[7]
    $DiskHealth  = "{0} {1} {2} {3}" -f $DiskCount,$FailedDisk,$CriticalDisk,$DegradedDisk 
    $maxErrorMargin = ((MegaCli -AdpBbuCmd -GetBbuStatus -aAll | findstr "Max Error") -Split ":")[1]
    
    $DiskInfo = @{
        Disk1 = $Disk1
        Disk2 = $Disk2
        DiskHealth = $DiskHealth
        ErrorMargin = $maxErrorMargin
    }
} else {
    $DiskInfo = $false
}



#####################
## DIRTY SHUTDOWNS ##
#####################

$mostRecentDirtyShutdown = (Get-EventLog -LogName 'System' -EntryType WARNING,ERROR |
Where-Object -FilterScript {$_.EventID -eq 6008 } |
Sort-Object -Property TimeGenerated -Descending |
Select-Object -First 1).TimeGenerated

if ($null -eq $mostRecentDirtyShutdown) {
    $mostRecentDirtyShutdown = "Unknown"
}

$mostRecentCleanShutdown = (Get-EventLog -LogName 'System'|
Where-Object -FilterScript {$_.EventID -eq 6006 } |
Sort-Object -Property TimeGenerated -Descending |
Select-Object -First 1).TimeGenerated

if ($null -eq $mostRecentCleanShutdown) {
    $mostRecentCleanShutdown = "Unknown"
}

$endTime = Get-Date
$startTime = $endTime.AddDays(-7)

$numOfRecentShutdowns = (
    (Get-EventLog -LogName 'System' -After $startTime -Before $endTime -EntryType WARNING,ERROR |
    Where-Object -FilterScript {$_.EventID -eq 6008} | Measure-Object).Count
) + (
    (Get-EventLog -LogName 'System' -After $startTime -Before $endTime |
    Where-Object -FilterScript {$_.EventID -eq 6006} | Measure-Object).Count
)

$shutdownData = @{
    mostRecentCleanShutdown = $mostRecentCleanShutdown
    mostRecentDirtyShutdown = $mostRecentDirtyShutdown
    numOfRecentShutdowns = $numOfRecentShutdowns
    Uptime = $uptimeString
    UptimeDays = $uptime.Days
}


@{
    GenData = $genData
    DriveData = $driveInfo
    DiskData = $DiskInfo
    ServiceData = $servicesTable
    ShutdownData = $shutdownData
    ArpTable = (arp -a) | Out-String
} | Export-Clixml -Path "D:/Store/checktools.xml"