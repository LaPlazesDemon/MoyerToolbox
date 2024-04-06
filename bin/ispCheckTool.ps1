$nl = "
"
Function Get-ServicesTable {
    param (
        [Hashtable]$Data
    )
    $table = @()

    foreach ($service in $Data.Keys) {
        $customObject = New-Object PSObject
        $customObject | Add-Member -Type NoteProperty -Name "Service Name" -Value $service
        $customObject | Add-Member -Type NoteProperty -Name "Status" -Value $Data[$service]["Status"]
        $customObject | Add-Member -Type NoteProperty -Name "Startup Type" -Value $Data[$service]["Startup Type"]
        $table += $customObject
    }

    $tableString = $table | Format-Table | Out-String
    return $tableString
}

$ping = New-Object System.Net.NetworkInformation.Ping

Function Run-ISPCheckTool {
    Copy-Item -Path "$Global:binPath/remoteIspCheckTool.ps1" -Destination "\\$Global:ipAddress\d$\Store\checktools.ps1" -ErrorAction Stop
    Invoke-Command -ComputerName "$Global:ipAddress" -ScriptBlock { & powershell -File D:\Store\checktools.ps1 } -Credential $Global:credentials -ErrorAction Stop
    $checktools = Import-Clixml -Path "\\$ipAddress\d$\Store\checktools.xml" -ErrorAction Stop

    ## Last Shutdown Type
    function TryParseDateTime($inputString, $format) {
        [DateTime]$parsedDateTime = [DateTime]::MinValue
        $culture = [System.Globalization.CultureInfo]::InvariantCulture
        $styles = [System.Globalization.DateTimeStyles]::None
        $success = [DateTime]::TryParseExact(
            $inputString, 
            $format, 
            $culture, 
            $styles, 
            [ref]$parsedDateTime
        )
        return $success, $parsedDateTime
    }
    
    $cleanShutdownFormat = "MM/dd/yyyy HH:mm:ss"
    $dirtyShutdownFormat = "MM/dd/yyyy HH:mm:ss"
    
    # Parse clean shutdown time
    $result, $cleanShutdown = TryParseDateTime $checktools.ShutdownData.mostRecentCleanShutdown $cleanShutdownFormat
    if (-not $result) {
        $cleanShutdown = $null
    }
    
    # Parse dirty shutdown time
    $result, $dirtyShutdown = TryParseDateTime $checktools.ShutdownData.mostRecentDirtyShutdown $dirtyShutdownFormat
    if (-not $result) {
        $dirtyShutdown = $null
    }
    
    # Now $cleanShutdown and $dirtyShutdown contain either the parsed DateTime or $null if parsing was unsuccessful
    

    $lastRebootType = if ($cleanShutdown -gt $dirtyShutdown) {"Clean Shutdown"} 
    elseif ($dirtyShutdown -gt $cleanShutdown) {"Dirty Shutdown"}
    else {"Unknown"}

    ## Error Margin
    try {
        $maxErrorMargin = [double]::Parse($checktools.DiskData.ErrorMargin.TrimEnd('%').Trim())
    } catch {}

    ## Ris Version
    $risVersion = if ($Global:Ris20) {"2.0"} else {"1.0"}

    ## Flag Text

    $flagString = ""

    if ($Global:Ris20) {
        if ($checktools.ServiceData.CServe.Status -ne 1) {$flagString += "$nl- CServe Service is running"}
        if ($checktools.ServiceData."DHCP Server".Status -ne 1) {$flagString += "$nl- DHCP Server Service is running"}
        if ($checktools.ServiceData.RealTimeServices.Status -ne 1) {$flagString += "$nl- RealTimeService Service is running"}
        if ($checktools.ServiceData.CServe."Startup Type" -ne "Disabled") {$flagString += "$nl- CServe Service is not set to disabled"}
        if ($checktools.ServiceData."DHCP Server"."Startup Type" -ne "Disabled") {$flagString += "$nl- DHCP Server Service is not set to disabled"}
        if ($checktools.ServiceData.RealTimeServices."Startup Type" -ne "Disabled") {$flagString += "$nl- RealTimeService Service is not set to disabled"}
    } else {
        if ($checktools.ServiceData.CServe.Status -ne 4) {$flagString += "$nl- CServe Service is not running"}
        if ($checktools.ServiceData."DHCP Server".Status -ne 4) {$flagString += "$nl- DHCP Server Service is not running"}
        if ($checktools.ServiceData.RealTimeServices.Status -ne 4) {$flagString += "$nl- RealTimeService Service is not running"}
        if ($checktools.ServiceData.CServe."Startup Type" -ne "Auto") {$flagString += "$nl- CServe Service is not set to automatic"}
        if ($checktools.ServiceData."DHCP Server"."Startup Type" -ne "Auto") {$flagString += "$nl- DHCP Server Service is not set to automatic"}
        if ($checktools.ServiceData.RealTimeServices."Startup Type" -ne "Manual") {$flagString += "$nl- RealTimeService Service is not set to manual"}
    }

    if ($lastRebootType -eq "Dirty Shutdown") {$flagString += "$nl- Last shutdown was a dirty shutdown"}
    if ($checktools.ShutdownData.UptimeDays -gt 30) {$flagString += "$nl- Uptime is more than 30 days, reboot recommended"}
    if ($maxErrorMargin -gt 90) {$flagString += "$nl- Maximum Error Margin is greater than 90%, running a BBU Relearn Cycle is recommended"}
    if ($checktools.GenData.CpuUsage -gt 90) {$flagString += "$nl- CPU Usage is over 90%"}
    if ($checktools.GenData.RamUsage -gt 90) {$flagString += "$nl- RAM Usage is over 90%"}
    if (($checktools.DiskData)) {
        if (!($checktools.DiskData.DiskHealth -Match "Failed:0")) {$flagString += "$nl- Disk failure detected, replace immediately!"}
        else {
            if (!($checktools.DiskData.DiskHealth -Match "Critical:0")) {$flagString += "$nl- Disk failure predicted, replace immediately!"}
            if (!($checktools.DiskData.DiskHealth -Match "Degraded:0")) {$flagString += "$nl- Disk degradation detected, replace immediately!"}
        }
        if ($checktools.DiskData.Disk1 -Match "Unconfigured") {$flagString += "$nl- Disk 1 is unconfigured"}
        if ($checktools.DiskData.Disk2 -Match "Unconfigured") {$flagString += "$nl- Disk 2 is unconfigured"}
    }    
    foreach ($drive in $checktools.DriveData) {
        if ($drive."Free Bytes" -lt 1GB) {$flagString += "$nl- $($drive.Drive)/ has less than 1GB of free space left"}
        elseif ($drive."Free Bytes" -lt 2GB) {$flagString += "$nl- $($drive.Drive)/ has less than 2GB of free space left"}
    }
    if ("" -ne $flagString) {$flagString = "$($nl)Issues Found$nl=----------=$flagString$nl$nl"}


    $driveDataText = ""
    if ($checktools.DiskData -eq $false) {
        $driveDataText = "Virtual ISP, MegaRAID is not installed"
    } else {
        $driveDataText = "Disk Health: $($checktools.DiskData.DiskHealth)
Disk 1: $($checktools.DiskData.Disk1)
Disk 2: $($checktools.DiskData.Disk2)
Maximum Error Margin: $($checktools.DiskData.ErrorMargin)"
    }

    $fileText = "$($flagString)
General Data
=----------=
Store Number: $Global:storeNumber
RIS Version: $risVersion
Hostname: $($checktools.GenData.Hostname)
Model: $($checktools.GenData.Model)
Local Time: $($checktools.GenData.DateTime)
Timezone: $($checktools.GenData.Timezone)
CPU Usage: $($checktools.GenData.CpuUsage)%
RAM Usage: $($checktools.GenData.RamUsage)%


Drive Data
=--------=
$driveDataText

Drive    Free Space
-----    ----------
$($checktools.DriveData[0].Drive)/      $($checktools.DriveData[0]."Free Space")
$($checktools.DriveData[1].Drive)/      $($checktools.DriveData[1]."Free Space")
$($checktools.DriveData[2].Drive)/      $($checktools.DriveData[2]."Free Space")
$($checktools.DriveData[3].Drive)/      $($checktools.DriveData[3]."Free Space")
$($checktools.DriveData[4].Drive)/      $($checktools.DriveData[4]."Free Space")



Shutdown Data
=-----------=
ISP $($checktools.ShutdownData.Uptime)

Most Recent Clean Shutdown: $($checktools.ShutdownData.mostRecentCleanShutdown)
Most Recent Dirty Shutdown: $($checktools.ShutdownData.mostRecentDirtyShutdown)
Number of Recent Shutdowns: $($checktools.ShutdownData.numOfRecentShutdowns)

Last Reboot Type: $lastRebootType



Services
=------=$(Get-ServicesTable -Data $checktools.ServiceData)
DHCP Reservations
=---------------=$($checktools.ArpTable)
"
    $tempFilePath = [System.IO.Path]::GetTempFileName()
    $fileText| Set-Content $tempFilePath
    Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath

    Remove-Item -Path "\\$Global:ipAddress\d$\Store\checktools.ps1"
    Remove-Item -Path "\\$Global:ipAddress\d$\Store\checktools.xml"
    Remove-Item -Path "\\$Global:ipAddress\d$\Store\MegaSAS.log"
    Remove-Item -Path "\\$Global:ipAddress\d$\Store\CmdTool.log"
    
}