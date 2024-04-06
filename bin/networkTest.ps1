Add-Type -AssemblyName System.Windows.Forms


Function Start-PingJob ($ip) {

    Write-Host "Starting Job for $ip"
    return Test-Connection -ComputerName $ip -Count 1 -AsJob
}

Function Network-Check {

    $PingJobs = @{}
    $offlineText = "OFFLINE"
    $router = $offlineText
    $switch = $offlineText
    $WAP  = $offlineText
    $isp = $offlineText
    $bmc = $offlineText
    $dex = $offlineText
    $atg = $offlineText
    $chromebox = $offlineText
    $safe = $offlineText
    $backofficeprinter = $offlineText
    $bixprinter = $offlineText
    $7nowprinter = $offlineText
    $pos1 = $offlineText
    $pos2 = $offlineText
    $pos3 = $offlineText
    $pos4 = $offlineText
    $pos5 = $offlineText
    $backofficetext = ""

    if (Test-Connection -ComputerName "$ipPrefix.193" -Count 1) {

        ## ROUTER IS ONLINE

        Write-Host "Starting Jobs"
        $PingJobs["Router"] = Start-PingJob "$ipPrefix.193"
        $PingJobs["Switch"] = Start-PingJob "$ipPrefix.198"
        $PingJobs["WAP1"] = Start-PingJob "$ipPrefix.154"
        $PingJobs["WAP2"] = Start-PingJob "$ipPrefix.155" 
        $PingJobs["WAP3"] = Start-PingJob "$ipPrefix.156" 
        $PingJobs["WAP4"] = Start-PingJob "$ipPrefix.157" 
        $PingJobs["WAP5"] = Start-PingJob "$ipPrefix.158"
        
        $PingJobs["DEX"] = Start-PingJob "$ipPrefix.203"
        $PingJobs["ATG"] = Start-PingJob "$ipPrefix.7"

        $PingJobs["ISP"] = Start-PingJob "$ipPrefix.10"
        $PingJobs["BMC"] = Start-PingJob "$ipPrefix.5"

        $PingJobs["Chromebox1"] = Start-PingJob "$ipPrefix.185"
        $PingJobs["Chromebox2"] = Start-PingJob "$ipPrefix.186"
        $PingJobs["Chromebox3"] = Start-PingJob "$ipPrefix.187"
        $PingJobs["Chromebox4"] = Start-PingJob "$ipPrefix.188"
        $PingJobs["Chromebox5"] = Start-PingJob "$ipPrefix.189"
        $PingJobs["Chromebox6"] = Start-PingJob "$ipPrefix.190"

        if ($Global:Ris20) {
            $PingJobs["POS1"] = Start-PingJob "$Global:storeNumber-POS01"
            $PingJobs["POS2"] = Start-PingJob "$Global:storeNumber-POS02"
            $PingJobs["POS3"] = Start-PingJob "$Global:storeNumber-POS03"
            $PingJobs["POS4"] = Start-PingJob "$Global:storeNumber-POS04"
            $PingJobs["POS5"] = Start-PingJob "$Global:storeNumber-POS05"
        } else {
            $PingJobs["POS1"] = Start-PingJob "$ipPrefix.20"
            $PingJobs["POS2"] = Start-PingJob "$ipPrefix.21"
            $PingJobs["POS3"] = Start-PingJob "$ipPrefix.22"
            $PingJobs["POS4"] = Start-PingJob "$ipPrefix.23"
            $PingJobs["POS5"] = Start-PingJob "$ipPrefix.24"
        }

        $PingJobs["Back Office Printer"] = Start-PingJob "$ipPrefix.179"
        $PingJobs["Safe"] = Start-PingJob "$ipPrefix.178"
        $PingJobs["7Now Printer"] = Start-PingJob "$ipPrefix.246"
        $PingJobs["Bixolon Printer"] = Start-PingJob "$ipPrefix.230"


        $pingTimes = @(); $packetsLost = $false; $prevPingTime = $null; $diffs = @()
        $lossCounter = 0
        $minPingTime = [int]::MaxValue
        $maxPingTime = 0

        1..60 | ForEach-Object {
            $ping = Test-Connection -ComputerName "$Global:firstThree.193" -Count 1 -BufferSize 1500 -ErrorAction SilentlyContinue
            Write-Host "Ping successful with response time: $($ping.ResponseTime) ms"
            if ($null -eq $ping) {
                $packetsLost = $true 
                $lossCounter += 1
            } 
            else { 
                $pingTimes += $ping.ResponseTime 
                if ($ping.ResponseTime -lt $minPingTime) { $minPingTime = $ping.ResponseTime }
                if ($ping.ResponseTime -gt $maxPingTime) { $maxPingTime = $ping.ResponseTime }
                if ($null -ne $prevPingTime) { $diffs += [Math]::Abs($ping.ResponseTime - $prevPingTime) }
                $prevPingTime = $ping.ResponseTime 
            }
        }

        $avg = [Math]::Round(($pingTimes | Measure-Object -Average).Average)
        $jitter = [Math]::Round(($diffs | Measure-Object -Average).Average)


        Write-Host "Waiting on Jobs"
        $PingJobs.Values | Wait-Job
        Write-Host "Jobs Completed"

        $responses = @{}

        foreach ($key in $PingJobs.Keys) {
            $result = Receive-Job -Job $PingJobs[$key]
            $status = ""
            if ($result.StatusCode -eq 0) {
                $status = "Online"
                $responses[$key] = $true
            } else {
                $status = "Offline"
                $responses[$key] = $false

            }
            Write-Host "$key is $status"
            $PingJobs[$key] | Remove-Job
        }
        if ($responses["Router"]) {$router = "Online"}
        if ($responses["Switch"]) {$switch = "Online"}
        
        if ($responses["WAP1"]) {$WAP = "Online"} 
        elseif ($responses["WAP2"]) {$WAP = "Online"}
        elseif ($responses["WAP3"]) {$WAP = "Online"}
        elseif ($responses["WAP4"]) {$WAP = "Online"}
        elseif ($responses["WAP5"]) {$WAP = "Online"}

        if ($responses["DEX"]) {$dex = "Online"}
        if ($responses["ATG"]) {$atg = "Online"}
        
        if ($responses["ISP"]) {$isp = "Online"}
        if ($responses["BMC"]) {$bmc = "Online"}

        if ($responses["Chromebox1"]) {$chromebox = "Online (.185)"}
        elseif ($responses["Chromebox2"]) {$chromebox = "Online (.186)"}
        elseif ($responses["Chromebox3"]) {$chromebox = "Online (.187)"}
        elseif ($responses["Chromebox4"]) {$chromebox = "Online (.188)"}
        elseif ($responses["Chromebox5"]) {$chromebox = "Online (.189)"}
        elseif ($responses["Chromebox6"]) {$chromebox = "Online (.190)"}

        if ($responses["POS1"]) {$pos1 = "Online $(if ($Ris20) {"(.$(((Test-DNS "$storeNumber-POS01.storesp.7-11.com") -Split "\.")[3]))"})"}
        if ($responses["POS2"]) {$pos2 = "Online $(if ($Ris20) {"(.$(((Test-DNS "$storeNumber-POS02.storesp.7-11.com") -Split "\.")[3]))"})"}
        if ($responses["POS3"]) {$pos3 = "Online $(if ($Ris20) {"(.$(((Test-DNS "$storeNumber-POS03.storesp.7-11.com") -Split "\.")[3]))"})"}
        if ($responses["POS4"]) {$pos4 = "Online $(if ($Ris20) {"(.$(((Test-DNS "$storeNumber-POS04.storesp.7-11.com") -Split "\.")[3]))"})"}
        if ($responses["POS5"]) {$pos5 = "Online $(if ($Ris20) {"(.$(((Test-DNS "$storeNumber-POS05.storesp.7-11.com") -Split "\.")[3]))"})"}

        if ($responses["Safe"]) {$safe = "Online"}
        if ($responses["7Now Printer"]) {$7nowprinter = "Online"}
        if ($responses["Bixolon Printer"]) {$bixprinter = "Online"}
        if ($responses["Back Office Printer"]) {$backofficeprinter = "Online"}
        
        ## BACKOFFICE TEXT

        if ($Global:ConversionStore) {

            $backofficetext = "DNSDHCP Server -- $isp
Chromebox -- $chromebox"
        } else {
            if (($isp -eq "Online") -or ($bmc -eq "Online") -and ($chromebox -eq $offlineText)) {
                $backofficetext = "ISP -- $isp
BMC -- $bmc"
            } elseif (($isp -eq $offlineText) -and ($bmc -eq $offlineText) -and ($chromebox -ne $offlineText)) {
                $backofficetext = "Chromebox -- $chromebox"
            } else {
                $backofficetext = "ISP -- $isp
BMC -- $bmc
Chromebox -- $chromebox"
            }
        }
        


        $jitterText = ""
        $pingText = ""
        $packetText = ""

        if ($jitter -gt 20) {
            $jitterText = "Network is HIGHLY unstable"
        } elseif ($jitter -gt 15) {
            $jitterText = "Network is very unstable" 
        } elseif ($jitter -gt 7) {
            $jitterText = "Network is slightly unstable"
        } else {
            $jitterText = "Network is stable"
        }

        if ($avg -gt 1000) {
            $pingText = "Ping times are EXTREMELY high`n"
        } elseif ($avg -gt 350) {
            $pingText = "Ping times are very high"
        } elseif ($avg -gt 150) {
            $pingText = "Ping times are high"
        } else {
            $pingText = "Ping times are good"
        }

        if ($packetsLost) {
            $packetText = "
            
WARNING Packet Loss Detected
$lossCounter of 60 Packets Lost"
        }

        $stabilityTestInfo = "Heavy Packet Stability Test
=-------------------------=
Maximum Ping Time: $maxPingTime ms
Minimum Ping Time: $minPingTime ms
Average Ping Time: $avg ms
$pingText

Average Jitter: $jitter ms
$jitterText $packetText"
            
$networkInfo = "Network Check
Store: $storeNumber
=-----------=
Router -- $router
Switch -- $switch
WAP -- $WAP

$backofficetext

DEX -- $dex
ATG -- $atg

POS1 -- $pos1
POS2 -- $pos2
POS3 -- $pos3
POS4 -- $pos4
SCO  -- $pos5

Safe -- $safe
7Now Printer -- $7nowprinter
Bixolon Printer -- $bixPrinter
Back Office Printer -- $backofficeprinter

$stabilityTestInfo"

    if (-not $Global:networkCheckForm -or $Global:networkCheckForm.IsDisposed) {
        $Global:networkCheckForm = New-Object System.Windows.Forms.Form
        $Global:networkCheckForm.Text = "Network Check"
        $Global:networkCheckForm.Size = New-Object System.Drawing.Size(300, 675)

        $Global:networkCheckForm.Controls.Add((Form-TextBox $networkInfo))
        $Global:networkCheckForm.Controls.Add((Form-CopyButton))
    }

    Form-TextBox($networkInfo)
    if (-not $Global:networkCheckForm.Visible) {
        $Global:networkCheckForm.Show()
    }

    } else {
        Show-Error -message "Store Network is Offline!"
    }
}