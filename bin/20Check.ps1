
Function Check-20 {

    $RIS1Checks = 0
    $RIS2Checks = 0
    
    try {
        $dnsCheck = [System.Net.Dns]::GetHostAddresses("$Global:storeNumber-POS01.storesp.7-11.com")
        $RIS2Checks += 1
    } catch {
        $RIS1Checks += 1
    }
    
    if (($ping.Send("$ipPrefix.10", $timeout)).Status -ne "Success") {
        if (($ping.Send("$ipPrefix.185", $timeout)).Status -eq "Success") {$RIS2Checks += 1}
        elseif (($ping.Send("$ipPrefix.186", $timeout)).Status -eq "Success") {$RIS2Checks += 1}
        elseif (($ping.Send("$ipPrefix.187", $timeout)).Status -eq "Success") {$RIS2Checks += 1}
        elseif (($ping.Send("$ipPrefix.188", $timeout)).Status -eq "Success") {$RIS2Checks += 1}
        elseif (($ping.Send("$ipPrefix.189", $timeout)).Status -eq "Success") {$RIS2Checks += 1}
        elseif (($ping.Send("$ipPrefix.190", $timeout)).Status -eq "Success") {$RIS2Checks += 1}
        else {$RIS1Checks += 1}
    }

    # POS 711.Peripehral Check
    # POS Registry Check
    # ISP POSIMG hash check  
}