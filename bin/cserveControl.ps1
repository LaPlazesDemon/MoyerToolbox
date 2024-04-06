Add-Type -AssemblyName System.Windows.Forms

$buttonSize = New-Object System.Drawing.Size(135, 28)
$button = New-Object System.Windows.Forms.Button

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Font = New-Object System.Drawing.Font("Consolas",10,[System.Drawing.FontStyle]::Regular)
$textBox.Dock = 'Fill'
$textBox.ReadOnly = $true

$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "Copy"
$copyButton.Dock = 'Bottom'
$copyButton.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($textBox.Text)
})
Function DisableCserveButtons {
    $startController.Enabled = $false
    $stopController.Enabled = $false
    $stopFuel.Enabled = $false
    $startFuel.Enabled = $false
    $startMom.Enabled = $false
    $stopMom.Enabled = $false
    $startRTS.Enabled = $false
    $stopRTS.Enabled = $false
    $startSafe.Enabled = $false
    $stopSafe.Enabled = $false
    $stopAll.Enabled = $false
    $startAll.Enabled = $false
}

Function EnableCserveButtons {
    $startController.Enabled = $true
    $stopController.Enabled = $true
    $stopFuel.Enabled = $true
    $startFuel.Enabled = $true
    $startMom.Enabled = $true
    $stopMom.Enabled = $true
    $startRTS.Enabled = $true
    $stopRTS.Enabled = $true
    $startSafe.Enabled = $true
    $stopSafe.Enabled = $true
    $stopAll.Enabled = $true
    $startAll.Enabled = $true
}
Function Cserve-Control {

    $cserveForm = New-Object System.Windows.Forms.Form
    $cserveForm.Text = "Cserve Panel"
    $cserveForm.Size = New-Object System.Drawing.Size(330,325)

    $startAll = New-Object System.Windows.Forms.Button
    $startAll.Text = "Start All"
    $startAll.Location = New-Object System.Drawing.Point(15,10)
    $startAll.Size = $buttonSize
    $startAll.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve start all" -Wait
        EnableCserveButtons
    })

    $stopAll = New-Object System.Windows.Forms.Button
    $stopAll.Text = "Stop All"
    $stopAll.Location = New-Object System.Drawing.Point(160, 10)
    $stopAll.Size = $buttonSize
    $stopAll.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve stop all" -Wait
        EnableCserveButtons
    })

    $startController = New-Object System.Windows.Forms.Button
    $startController.Text = "Start Controller"
    $startController.Location = New-Object System.Drawing.Point(15, 45)
    $startController.Size = $buttonSize
    $startController.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve start controller" -Wait
        EnableCserveButtons
    })

    $stopController = New-Object System.Windows.Forms.Button
    $stopController.Text = "Stop Controller"
    $stopController.Location = New-Object System.Drawing.Point(160, 45)
    $stopController.Size = $buttonSize
    $stopController.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve stop controller" -Wait
        EnableCserveButtons
    })

    $startFuel = New-Object System.Windows.Forms.Button
    $startFuel.Text = "Start Fuel"
    $startFuel.Location = New-Object System.Drawing.Point(15, 80)
    $startFuel.Size = $buttonSize
    $startFuel.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve start fuel" -Wait
        EnableCserveButtons
    })

    $stopFuel = New-Object System.Windows.Forms.Button
    $stopFuel.Text = "Stop Fuel"
    $stopFuel.Location = New-Object System.Drawing.Point(160, 80)
    $stopFuel.Size = $buttonSize
    $stopFuel.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve stop fuel" -Wait
        EnableCserveButtons
    })

    $startMom = New-Object System.Windows.Forms.Button
    $startMom.Text = "Start MOM"
    $startMom.Location = New-Object System.Drawing.Point(15, 115)
    $startMom.Size = $buttonSize
    $startMom.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve start mom" -Wait
        EnableCserveButtons
    })

    $stopMom = New-Object System.Windows.Forms.Button
    $stopMom.Text = "Stop MOM"
    $stopMom.Location = New-Object System.Drawing.Point(160, 115)
    $stopMom.Size = $buttonSize
    $stopMom.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve stop mom" -Wait
        EnableCserveButtons
    })

    $startRTS = New-Object System.Windows.Forms.Button
    $startRTS.Text = "Start RealTimeServices"
    $startRTS.Location = New-Object System.Drawing.Point(15, 150)
    $startRTS.Size = $buttonSize
    $startRTS.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve start realtimeservices" -Wait
        EnableCserveButtons
    })

    $stopRTS = New-Object System.Windows.Forms.Button
    $stopRTS.Text = "Stop RealTimeServices"
    $stopRTS.Location = New-Object System.Drawing.Point(160, 150)
    $stopRTS.Size = $buttonSize
    $stopRTS.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve stop realtimeservices" -Wait
        EnableCserveButtons
    })

    $startSafe = New-Object System.Windows.Forms.Button
    $startSafe.Text = "Start Safe"
    $startSafe.Location = New-Object System.Drawing.Point(15, 185)
    $startSafe.Size = $buttonSize
    $startSafe.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve start safe" -Wait
        EnableCserveButtons
    })

    $stopSafe = New-Object System.Windows.Forms.Button
    $stopSafe.Text = "Stop Safe"
    $stopSafe.Location = New-Object System.Drawing.Point(160, 185)
    $stopSafe.Size = $buttonSize
    $stopSafe.Add_Click({
        DisableCserveButtons
        Start-Process $psexecPath "\\s$storeNumber cserve stop safe" -Wait
        EnableCserveButtons
    })

    $status = New-Object System.Windows.Forms.Button
    $status.Text = "Cserve Status"
    $status.Location = New-Object System.Drawing.Point(15, 220)
    $status.Size = New-Object System.Drawing.Size(280, 28)
    $status.Add_Click({
        ## GET CSERVE STATUS
        DisableCserveButtons

        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $psexecPath
        $processInfo.Arguments = "\\s$storeNumber cserve"
        $processInfo.RedirectStandardOutput = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null
        
        $outputString = $process.StandardOutput.ReadToEnd()
        $process.WaitForExit()


        $cserveForm = New-Object System.Windows.Forms.Form
        $cserveForm.Text = "Cserve Status $storeNumber"
        $cserveForm.Size = New-Object System.Drawing.Size(550,650)

        $textBox = Form-TextBox($outputString)

        $cserveForm.Controls.Add($textBox)
        $cserveForm.Controls.Add($copyButton)

        $cserveForm.ShowDialog()
        EnableCserveButtons

    })

    $restartAll = New-Object System.Windows.Forms.Button
    $restartAll.Location = New-Object System.Drawing.Point(15,250)
    $restartAll.Size = New-Object System.Drawing.Size(280, 28)
    $restartAll.Text = "Restart All"
    $restartAll.Add_Click({
        Start-Process $psexecPath "\\s$storeNumber cserve stop all && cserve start all"
        $cserveForm.Close()
    })

    $cserveForm.Controls.Add($status)
    $cserveForm.Controls.Add($startController)
    $cserveForm.Controls.Add($stopController)
    $cserveForm.Controls.Add($startFuel)
    $cserveForm.Controls.Add($stopFuel)
    $cserveForm.Controls.Add($startMom)
    $cserveForm.Controls.Add($stopMom)
    $cserveForm.Controls.Add($startRTS)
    $cserveForm.Controls.Add($stopRTS)
    $cserveForm.Controls.Add($startSafe)
    $cserveForm.Controls.Add($stopSafe)
    $cserveForm.Controls.Add($stopAll)
    $cserveForm.Controls.Add($startAll)
    $cserveForm.Controls.Add($restartAll)
    $cserveForm.ShowDialog() | Out-Null

    
}