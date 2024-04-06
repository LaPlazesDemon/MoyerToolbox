Function Get-PingTimes($ip, $mac) {
    $pingTimes = @(); $packetsLost = $false; $prevPingTime = $null; $diffs = @()
    $lossCounter = 0
    $minPingTime = [int]::MaxValue
    $maxPingTime = 0

    1..10 | ForEach-Object {
        $ping = Test-Connection -ComputerName "$ip" -Count 1 -BufferSize 1500 -ErrorAction SilentlyContinue
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

    return @{
        "IP Address" = $ip;
        "MAC Address" = $mac;
        "Avg Ping" = [string]$avg+"ms";
        "Min" = [string]$minPingTime+"ms";
        "Max" = [string]$maxPingTime+"ms";
        "Jitter" = [string]$jitter+"ms";
        "Packets Lost" = [string]($lossCounter * 10) + "%"
    }
}

Function Run-7MDDiag {
    
    if ((Test-Connection -ComputerName "Jr$storeNumber") -and (Test-Connection -ComputerName "Jv$storeNumber")) {

        $stats = @()
        $7mdsArp = Invoke-Expression "echo y | plink -pw $Global:pass $env:USERNAME@$Global:firstThree.193 `"show arp | match 10:DC:B6`""
        if ($7mdsArp -match "FATAL ERROR") {
            Show-Error -message "Failed to login to router`n`nError: $7mdsArp"
        } else {
            $7mds = $7mdsArp -Split "`n"
            if ($7mds.Length -gt 0) {
                foreach ($device in $7mds) {
                    if ($null -ne $device) {
                        $ip = ($device -Split " ")[1]
                        $mac = ($device -Split " ")[0]
                        $stats += Get-PingTimes $ip $mac
                    }
                }
                $columnOrder = @("IP Address", "MAC Address", "Avg Ping", "Jitter", "Min", "Max", "Packets Lost")

                # Create custom objects and display as table
                $7MDTableOutput = ($stats | ForEach-Object {
                    $obj = New-Object PSObject
                    foreach ($col in $columnOrder) {
                        $obj | Add-Member -MemberType NoteProperty -Name $col -Value $_[$col]
                    }
                    $obj
                } | Format-Table -Property $columnOrder -AutoSize)

                Write-Host ($7MDTableOutput | Out-String)

                
            } else {
                $7MDTableOutput =  "No 7MDs were found in the ARP table."
            }

            $apCommand = Invoke-Expression "echo y | plink -pw $Global:pass $env:USERNAME@$Global:firstThree.198 `"show lldp neighbors interface ge-0/0/46;show lldp neighbors interface ge-0/0/47`""
            $apCommandSplit = $apCommand -Split "`n"
            foreach ($line in $apCommandSplit) {
                if ($line -match "System Description :") {
                    $apType = "Access Point Type: "+($line -Split ":")[1]
                } elseif ($line -match "Local Interface") {
                    $apInterface = "Access Point Interface: "+($line -Split ":")[1]
                }
            }

            if ($Ris20) {
                
            }

            $tempFilePath = [System.IO.Path]::GetTempFileName()
            "$($7MDTableOutput | Out-String)$apType
$apInterface" | Set-Content $tempFilePath
            Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath
        }
        
    } else {
        Show-Error -message "Router and/or Switch are offline or not responding to network requests"
    }
}

