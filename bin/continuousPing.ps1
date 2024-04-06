Add-Type -AssemblyName System.Windows.Forms

$ping = New-Object System.Net.NetworkInformation.Ping
$timeout = 1000


Function Get-DeviceForPing {
    $Global:pingForm = New-Object System.Windows.Forms.Form
    $Global:pingForm.Text = "Continuous Ping..."
    $Global:pingForm.Size = New-Object System.Drawing.Size(260,300)
    $Global:pingForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    $routerButton = New-Object System.Windows.Forms.Button
    $routerButton.Text = "Router"
    $routerButton.Location = New-Object System.Drawing.Point(15,10)
    $routerButton.Size = New-Object System.Drawing.Size(100, 35)
    $routerButton.Add_Click({Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $Global:firstThree.193 -t";$pingForm.Close()})

    $switchButton = New-Object System.Windows.Forms.Button
    $switchButton.Text = "Switch"
    $switchButton.Location = New-Object System.Drawing.Point(125, 10)
    $switchButton.Size = New-Object System.Drawing.Size(100,35)
    $switchButton.Add_Click({Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $Global:firstThree.198 -t";$pingForm.Close()})

    $ispButton = New-Object System.Windows.Forms.Button
    $ispButton.Text = "ISP"
    $ispButton.Location = New-Object System.Drawing.Point(15,50)
    $ispButton.Size = New-Object System.Drawing.Size(100,35)
    $ispButton.Add_Click({Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $Global:firstThree.10 -t";$pingForm.Close()})

    $pos1Button = New-Object System.Windows.Forms.Button
    $pos1Button.Text = "POS 1"
    $pos1Button.Location = New-Object System.Drawing.Point(125, 50)
    $pos1Button.Size = New-Object System.Drawing.Size(100,35)
    $pos1Button.Add_Click({
        if ($Ris20) {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $storeNumber-POS01.storesp.7-11.com -t";$pingForm.Close()} 
        else {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $Global:firstThree.20 -t";$pingForm.Close()}
    })

    $pos2Button = New-Object System.Windows.Forms.Button
    $pos2Button.Text = "POS 2"
    $pos2Button.Location = New-Object System.Drawing.Point(15, 90)
    $pos2Button.Size = New-Object System.Drawing.Size(100,35)
    $pos2Button.Add_Click({
        if ($Ris20) {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $storeNumber-POS02.storesp.7-11.com -t";$pingForm.Close()} 
        else {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $Global:firstThree.21 -t";$pingForm.Close()}
    })

    $pos3Button = New-Object System.Windows.Forms.Button
    $pos3Button.Text = "POS 3"
    $pos3Button.Location = New-Object System.Drawing.Point(125, 90)
    $pos3Button.Size = New-Object System.Drawing.Size(100,35)
    $pos3Button.Add_Click({
        if ($Ris20) {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $storeNumber-POS03.storesp.7-11.com -t";$pingForm.Close()} 
        else {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $Global:firstThree.22 -t";$pingForm.Close()}
    })

    $pos4Button = New-Object System.Windows.Forms.Button
    $pos4Button.Text = "POS 4"
    $pos4Button.Location = New-Object System.Drawing.Point(15, 130)
    $pos4Button.Size = New-Object System.Drawing.Size(100,35)
    $pos4Button.Add_Click({
        if ($Ris20) {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $storeNumber-POS04.storesp.7-11.com -t";$pingForm.Close()} 
        else {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $Global:firstThree.23 -t";$pingForm.Close()}
    })

    $pos5Button = New-Object System.Windows.Forms.Button
    $pos5Button.Text = "TaBaSCO"
    $pos5Button.Location = New-Object System.Drawing.Point(125, 130)
    $pos5Button.Size = New-Object System.Drawing.Size(100,35)
    $pos5Button.Add_Click({
        if ($Ris20) {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $storeNumber-POS05.storesp.7-11.com -t";$pingForm.Close()} 
        else {Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $Global:firstThree.24 -t";$pingForm.Close()}
    })

    $wapButton = New-Object System.Windows.Forms.Button
    $wapButton.Text = "WAP"
    $wapButton.Location = New-Object System.Drawing.Point(15, 170)
    $wapButton.Size = New-Object System.Drawing.Size(100,35)
    $wapButton.Add_Click({
        $pingForm.Close()

        if (($ping.Send("$Global:firstThree.154", $timeout)).Status -eq "Success") {$wapIP = "$Global:firstThree.154"}
        elseif (($ping.Send("$Global:firstThree.155", $timeout)).Status -eq "Success") {$wapIP = "$Global:firstThree.155"}
        elseif (($ping.Send("$Global:firstThree.156", $timeout)).Status -eq "Success") {$wapIP = "$Global:firstThree.156"}
        elseif (($ping.Send("$Global:firstThree.157", $timeout)).Status -eq "Success") {$wapIP = "$Global:firstThree.157"}
        elseif (($ping.Send("$Global:firstThree.158", $timeout)).Status -eq "Success") {$wapIP = "$Global:firstThree.158"}
        Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $wapIP -t";
    });

    $7mdButton = New-Object System.Windows.Forms.Button
    $7mdButton.Text = "7MDs"
    $7mdButton.Location = New-Object System.Drawing.Point(125,170)
    $7mdButton.Size = New-Object System.Drawing.Size(100, 35)
    $7mdButton.Add_Click({
        $7mdButton.Enabled = $false
        $wapButton.Enabled = $false
        $pos1Button.Enabled = $false
        $pos2Button.Enabled = $false
        $pos3Button.Enabled = $false
        $pos4Button.Enabled = $false
        $pos5Button.Enabled = $false
        $ispButton.Enabled = $false
        $switchButton.Enabled = $false
        $routerButton.Enabled = $false
        $chromeboxButton.Enabled = $false
        $response = (Invoke-Expression "echo y | plink -pw $Global:pass $env:USERNAME@$Global:firstThree.193 `"show arp | match 10:DC:B6`"") -Split "\n"
        if ($response.Length -gt 0) {
            foreach ($device in $response) {
                if ($null -ne $device) {
                    $ip = ($device -Split " ")[1]
                    Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $ip -t"
                }
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("No 7MDs were found in the ARP table. Confirm there are 7MDs on the network", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
        $pingForm.Close()
    })

    $chromeboxButton = New-Object System.Windows.Forms.Button
    $chromeboxButton.Text = "Chromebox"
    $chromeboxButton.Location = New-Object System.Drawing.Point(15, 210)
    $chromeboxButton.Size = New-Object System.Drawing.Size(100,35)
    $chromeboxButton.Add_Click({
        $7mdButton.Enabled = $false
        $wapButton.Enabled = $false
        $pos1Button.Enabled = $false
        $pos2Button.Enabled = $false
        $pos3Button.Enabled = $false
        $pos4Button.Enabled = $false
        $pos5Button.Enabled = $false
        $ispButton.Enabled = $false
        $switchButton.Enabled = $false
        $routerButton.Enabled = $false
        $chromeboxButton.Enabled = $false

        if (($ping.Send("$Global:firstThree.185", $timeout)).Status -eq "Success") {$cbIP = "$Global:firstThree.185"}
        elseif (($ping.Send("$Global:firstThree.186", $timeout)).Status -eq "Success") {$cbIP = "$Global:firstThree.186"}
        elseif (($ping.Send("$Global:firstThree.187", $timeout)).Status -eq "Success") {$cbIP = "$Global:firstThree.187"}
        elseif (($ping.Send("$Global:firstThree.188", $timeout)).Status -eq "Success") {$cbIP = "$Global:firstThree.188"}
        elseif (($ping.Send("$Global:firstThree.189", $timeout)).Status -eq "Success") {$cbIP = "$Global:firstThree.189"}
        elseif (($ping.Send("$Global:firstThree.190", $timeout)).Status -eq "Success") {$cbIP = "$Global:firstThree.190"}
        else {
            Show-Error "Unable to find chromebox dynamically defaulting to $Global:firstThree.185"
            $cbIP = "$Global:firstThree.185"
        }

        Start-Process cmd.exe -ArgumentList "/K mode 75,12&ping $cbIP -t";

        $pingForm.Close()
    })

    $pingForm.Controls.Add($7mdButton)
    $pingForm.Controls.Add($wapButton)
    $pingForm.Controls.Add($pos1Button)
    $pingForm.Controls.Add($pos2Button)
    $pingForm.Controls.Add($pos3Button)
    $pingForm.Controls.Add($pos4Button)
    $pingForm.Controls.Add($pos5Button)
    $pingForm.Controls.Add($ispButton)
    $pingForm.Controls.Add($switchButton)
    $pingForm.Controls.Add($routerButton)
    $pingForm.Controls.Add($chromeboxButton)
    $pingForm.ShowDialog() | Out-Null
}