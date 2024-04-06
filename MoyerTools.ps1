Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
Add-Type -AssemblyName System.Management.Automation

$Global:path = $PWD.Path
$Global:psexecPath = "W:/HD/Brice/Dev/MoyerToolbox/psexec.exe"
$Global:binPath = "W:/HD/Brice/Dev/MoyerToolbox/bin"
$Global:config = (Get-Content -Path "$binPath/config.json") | ConvertFrom-Json
$Global:formIcon = New-Object system.drawing.icon("$binPath/OIP.ico")

. "$binPath\posVersionAudit.ps1"
. "$binPath\showDeviceBindings.ps1"
. "$binPath\continuousPing.ps1"
. "$binPath\connectTo.ps1"
. "$binPath\passportValidation.ps1"
. "$binPath\networkTest.ps1"
. "$binPath\networkCheck.ps1"
. "$binPath\cserveControl.ps1"
. "$binPath\posHealthCheck.ps1"
. "$binPath\remoteClean.ps1"
. "$binPath\posPortChecks.ps1"
. "$binPath\momCheck.ps1"
. "$binPath\ispCheckTool.ps1"
. "$binPath\getUsers.ps1"
. "$binPath\optionsPanel.ps1"
. "$binPath\7MDdiag.ps1"
. "$binPath\getPOSTransactions.ps1"
. "$binPath\telemetryProcessing.ps1"
. "$binPath\DEXcommands.ps1"


$options = @(
    "  -- General --",
    "My Preferences...",
    # "2.0 Check",
    "MOM Check",
    "Open TabaScope",
    "Show Users",
    # "Get Store Config",
    "",
    "  -- DEX --",
    "Force Reload",
    "Smart Reload",
    "Fuel Status",
    "DEX Forecourt Status",
    # "*Show DEX Config",
    "",
    "  -- Fuel --",
    "Serial ATG Test",
    "Validate XMLs",
    "Reboot EDH",
    "Reload EDH Config File",
    "",
    "  -- Networking --",
    "Network Check Tool",
    "Show All Interfaces",
    "Show Device Bindings",
    "7MD Diagnostic",
    "Show Policies",
    #"Reactivate WAP",
    "",
    "  -- ISP --",
    "CServe...",
    "Day Mapping Error Check",
    "Interim ISP Check",
    "ISP Check Tool",
    "Start BBU Relearn",
    # "Clean C:/ Drive",
    # "Clean S:/ Drive",
    "View ISP Files",
    "",
    "  -- POS --",
    "POS Ports Check",
    "RDC into POS [Admin]",
    "View POS Files",
    "Show Message on POS",
    "Get Recent POS Transactions",
    ""
)

$ris2options = @(
    "  -- RIS 2.0 --",
    "POS Health Check",
    "POS Logoff",
    "POS Version Audit",
    "Reimage POS"
)

###############
## FUNCTIONS ##
###############

Function Show-Error {
    param([string]$message)
    [System.Windows.Forms.MessageBox]::Show($message, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}

Function Show-Info {
    param([string]$message)
    [System.Windows.Forms.MessageBox]::Show($message, "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

Function Get-POSIp {

    $script:returnValue = $false

    if (-not $storeNumber) {

        Show-Error -message "Please enter a Store # first"
        return $false
    } else {
        if ($posSelector.Value -eq 0) {

            $posIPForm = New-Object System.Windows.Forms.Form
            $posIPForm.Text = "POS IP Selector"
            $posIPForm.Size = New-Object System.Drawing.Size(185, 135)
            $posIPForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
            $posIPForm.StartPosition = "CenterScreen"
    
            $posIPLabel = New-Object System.Windows.Forms.Label
            $posIPLabel.Text = "Enter POS IP:"
            $posIPLabel.Location = New-Object System.Drawing.Point(10, 10)
            $posIPLabel.AutoSize = $true
            $posIPForm.Controls.Add($posIPLabel)
    
            $posIPText = New-Object System.Windows.Forms.Label
            $posIPText.Location = New-Object System.Drawing.Point(10, 30)
            $posIPText.AutoSize = $true
            $posIPText.Font = New-Object System.Drawing.Font($posIPText.Font.FontFamily, 12)
            $posIPText.Text = $Global:firstThree+"."
            $posIPForm.Controls.Add($posIPText)

            $posIPLast = New-Object System.Windows.Forms.TextBox
            $posIPLast.Location = New-Object System.Drawing.Point((80+(($Global:firstThree.Length)*2)), 26)
            $posIPLast.Size = New-Object System.Drawing.Size(45, 45)
            $posIPLast.Font = New-Object System.Drawing.Font($posIPLast.Font.FontFamily, 12)
            $posIPLast.Add_KeyDown({
                param($sender, $e)
                if ($e.KeyCode -eq 'Enter') {
                    $lastOctet = [int]$posIPLast.Text
                    if ($lastOctet -ge 20 -and $lastOctet -le 25) {
                        $script:returnValue = "$($posIPText.Text)$($posIPLast.Text)"  # Set the return value
                        $posIPForm.Close()
                    } else {
                        Show-Error -message "Enter a valid last octet (20 - 25)"
                    }
                }
            })
            $posIPForm.Controls.Add($posIPLast)
    
            $posIPButton = New-Object System.Windows.Forms.Button
            $posIPButton.Size = New-Object System.Drawing.Size(50, 22)
            $posIPButton.Text = "Enter"
            $posIPButton.Location = New-Object System.Drawing.Point(65, 60)
            $posIPButton.Add_Click({
                $lastOctet = [int]$posIPLast.Text
                    if ($lastOctet -ge 20 -and $lastOctet -le 25) {
                        $script:returnValue = "$($posIPText.Text)$($posIPLast.Text)"  # Set the return value
                        $posIPForm.Close()
                    } else {
                        Show-Error -message "Enter a valid last octet (20 - 25)"
                    }
            })
            $posIPForm.Controls.Add($posIPButton)
    
            $posIPForm.ShowDialog() | Out-Null
    
        } else {
            if ($Ris20) {
                $script:returnValue = "$storeNumber-POS0$($posSelector.Value).storesp.7-11.com"
            } else {
                $script:returnValue = "$firstThree.2$($posSelector.Value-1)"
            }
        }
        return $script:returnValue  # Return the value
    }

}

Function Disable-Buttons {
    $pingNetworkButton.Enabled = $false
    $posRDCAdminButton.Enabled = $false
    $posPsexecButton.Enabled = $false
    $connectToButton.Enabled = $false
    $optionDropdown.Enabled = $false
    $posRDCButton.Enabled = $false
    $posIMCButton.Enabled = $false
    $pingButton.Enabled = $false
    $runButton.Enabled = $false
}

Function Enable-Buttons {
    $pingNetworkButton.Enabled = $true
    $posRDCAdminButton.Enabled = $true
    $connectToButton.Enabled = $true
    $posPsexecButton.Enabled = $true
    $optionDropdown.Enabled = $true
    $posRDCButton.Enabled = $true
    $posIMCButton.Enabled = $true
    $pingButton.Enabled = $true
    $runButton.Enabled = $true
}

Function Check-ISP {
    if (Test-Connection -ComputerName "$firstThree.10" -Count 1) {
        return $true
    } else {
        $confirmation = [System.Windows.Forms.MessageBox]::Show("The ISP appears to be offline`nWould you like to attempt to run it anyways?",'','YesNo','Information')
        if ($confirmation -eq "Yes") {
            return $true
        } else {
            return $false
        }
    }

}

Function Check-DEX {
    if (Test-Connection -ComputerName "$firstThree.203" -Count 1) {
        return $true
    } else {
        $confirmation = [System.Windows.Forms.MessageBox]::Show("The DEX appears to be offline`nWould you like to attempt to run it anyways?",'','YesNo','Information')
        if ($confirmation -eq "Yes") {
            return $true
        } else {
            return $false
        }
    }

}

Function Form-TextBox($text) {
    $Global:textBox = New-Object System.Windows.Forms.TextBox
    $Global:textBox.Multiline = $true
    $Global:textBox.Font = New-Object System.Drawing.Font("Consolas",10,[System.Drawing.FontStyle]::Regular)
    $Global:textBox.Dock = 'Fill'
    $Global:textBox.ReadOnly = $true
    $Global:textBox.Text = $text

    return $textBox
}

Function Form-CopyButton {
    $copyButton = New-Object System.Windows.Forms.Button
    $copyButton.Text = "Copy"
    $copyButton.Dock = 'Bottom'
    $copyButton.Add_Click({[System.Windows.Forms.Clipboard]::SetText($Global:textBox.Text)})

    return $copyButton
}

Function Clear-Forms {
    if ($Global:dexFuelStatusForm.Visible) {$dexFuelStatusForm.Close()}
    if ($Global:networkCheckForm.Visible) {$networkCheckForm.Close()}
}

Function Add-Ris2Options {
    foreach ($item in $ris2options) {
        if (-not $optionDropdown.Items.Contains($item)) {
            $optionDropdown.Items.Add($item)
        }
    }
}

Function Remove-Ris2Options {
    foreach ($item in $ris2options) {
        if ($optionDropdown.Items.Contains($item)) {
            $optionDropdown.Items.Remove($item)
        }
    }
}

Function Toggle-POSButtons {
    if ($Global:ConversionStore) {
        $posIMCButton.Visible = $false
        $posRDCButton.Visible = $false
        $posPsexecButton.Visible = $false
        $posRDCAdminButton.Visible = $true
    } else {
        $posIMCButton.Visible = $true
        $posRDCButton.Visible = $true
        $posPsexecButton.Visible = $true
        $posRDCAdminButton.Visible = $false
    }
}

Function Check-YesNo($message, $title) {
    $check = [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($check -eq 'Yes') {
        return $true
    } else {
        return $false
    }
}

Function Hash-String($string) {
    $stringAsStream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($stringAsStream)
    $writer.write([string]$string)
    $writer.Flush()
    $stringAsStream.Position = 0
    return (Get-FileHash -InputStream $stringAsStream -Algorithm MD5).Hash
}

Function Router-Plink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$command
    )
    $p = $Global:pass
    $u = "$env:USERNAME@$Global:firstThree.193"
    $response = Invoke-Expression "echo y | plink -pw $p $u `"$command`""
    return $response
}

Function Switch-Plink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$command
    )
    $p = $Global:pass
    $u = "$env:USERNAME@$Global:firstThree.198"
    $response = Invoke-Expression "echo y | plink -pw $p $u `"$command`""
    return $response
}

Function Dex-Plink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$command
    )
    $u = "support@$Global:firstThree.203"
    $response = Invoke-Expression "echo y | plink -i $Global:binPath\keys\supportprodkey.ppk $u `"$command`""
    return $response
}

Function Test-DNS($hostname) {
    try {
        Write-Host "Testing DNS $hostname"
        $dns = [System.Net.Dns]::GetHostAddresses($hostname).IPAddressToString
        Write-Host "Receieved DNS"
        return $dns
    } catch {
        Write-Host "$hostname failed to resolve"
        return $false
    }
}

###################
## FORM CREATION ##
###################


# Create a form
$Global:form = New-Object System.Windows.Forms.Form
$form.Text = "Moyer Toolbox"
$form.Size = New-Object System.Drawing.Size(275, 255)
$form.FormBorderStyle = 'FixedDialog'
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false;
$form.Icon = $formIcon;

# Store Number label
$storeLabel = New-Object System.Windows.Forms.Label
$storeLabel.Text = "Enter Store Number"
$storeLabel.Location = New-Object System.Drawing.Point(10, 5)
$storeLabel.AutoSize = $true
$form.Controls.Add($storeLabel)


# Store Number textbox
$storeTextbox = New-Object System.Windows.Forms.TextBox
$storeTextbox.Location = New-Object System.Drawing.Point(10, 25)
$storeTextbox.Add_LostFocus({
    # If store number is changed, click the connect button to avoid confusion
    if ($storeTextbox.Text -ne $storeNumber) {
        $connectButton.PerformClick()
    }
})
$storeTextbox.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq 'Enter') {
        $connectButton.PerformClick()
    }
})
$form.Controls.Add($storeTextbox)


# Connect button
$connectButton = New-Object System.Windows.Forms.Button
$connectButton.Text = "Set Store ID"
$connectButton.Location = New-Object System.Drawing.Point(10, 48)
$connectButton.Size = New-Object System.Drawing.Size(100, 23)
$connectButton.Add_Click({

    $Global:storeNumber = $storeTextbox.Text
    $Global:ConversionStore = $false
    $storeTextbox.Enabled = $false
    Clear-Forms
    Disable-Buttons

    if ($storeNumber -ne "") {
        
        # Ensure the store number is formatted correctly
        if ($storeNumber -match '^\d{5}$') {

            # Attempt to resolve the 7-11 DNS name "s[Store Number]" "sXXXXX"
            $711DNSCheck = Test-Dns "s$storeNumber"
            if ($711DNSCheck) {
                
                # 7-11 Store found, assign variables and check for RIS 1.0/2.0
                $Global:ipAddress = $711DNSCheck
                $Global:firstThree = (($ipAddress.Split('.')[0..2]) -join '.')
                $Global:ipPrefix = $firstThree

                # RIS 2.0 DNS Check
                if (Test-Dns "$storeNumber-POS01.storesp.7-11.com") {

                    # 7-11 Store is RIS 2.0
                    Show-Info -message $config.conn_messages.RIS_20
                    Add-Ris2Options
                    $Global:Ris20 = $true

                    # Speedway Conversion site check
                    # Some speedways have both DNS names active so the check must be done regardless
                  
                    $SPWDNSCheck = Test-Dns "$storeNumber`dnsdhcp"
                    if ($SPWDNSCheck) {

                        # Speedway Conversion site found, assign variables
                        $Global:ConversionStore = $true
                        Show-Info -message $config.conn_messages.conversion_site

                        $Global:ipAddress = $SPWDNSCheck
                        $Global:firstThree = (($ipAddress.Split('.')[0..2]) -join '.')
                        $Global:ipPrefix = $firstThree
                    
                    }


                } else {

                    # 7-11 Store is RIS 1.0 / Cannot be a speedway conversion, additional check is not necessary
                    Show-Info -message $config.conn_messages.RIS_10
                    Remove-Ris2Options
                    $Global:Ris20 = $false
                    $Global:ConversionStore = $false

                }

            } else {

                # 7-11 Store not found test for speedway conversion site dns
                $SPWDNSCheck = Test-Dns "$storeNumber`dnsdhcp"
                if ($SPWDNSCheck) {

                    # Speedway Conversion site found, assign variables
                    $Global:ConversionStore = $true
                    Show-Info -message $config.conn_messages.conversion_site
                    $Global:ipAddress = $SPWDNSCheck
                    $Global:firstThree = (($ipAddress.Split('.')[0..2]) -join '.')
                    $Global:ipPrefix = $firstThree

                } else {
                    # Store was not found
                    Show-Error -message $config.conn_messages.store_not_found
                }
            }
            
        } else {
            # Store number entered was not valid
            Show-Error -message $config.conn_messages.bad_store_number
        }
    }
    

    Toggle-POSButtons
    $ipTextBox.Text = $ipAddress
    $storeTextbox.Enabled = $true
    Enable-Buttons
})
$form.Controls.Add($connectButton)

# # Store Number label
$ipLabel = New-Object System.Windows.Forms.Label
$ipLabel.Text = "Store IP"
$ipLabel.Location = New-Object System.Drawing.Point(145, 5)
$ipLabel.AutoSize = $true
$form.Controls.Add($ipLabel)

# IP Text Box
$ipTextBox = New-Object System.Windows.Forms.TextBox
$ipTextBox.Location = New-Object System.Drawing.Point(145, 25)
$ipTextBox.ReadOnly = $true
$form.Controls.Add($ipTextBox)

# Copy IP button
$copyIpButton = New-Object System.Windows.Forms.Button
$copyIpButton.Text = "Copy IP"
$copyIpButton.Location = New-Object System.Drawing.Point(145, 48)
$copyIpButton.Size = New-Object System.Drawing.Size(100, 23)
$copyIpButton.Add_Click({
    [System.Windows.Forms.Clipboard]::SetText($ipAddress)
});

$form.Controls.Add($copyIpButton)

$hr1 = New-Object System.Windows.Forms.Label
$hr1.AutoSize = $false
$hr1.Height = 1 
$hr1.Width = 245
$hr1.BackColor = [System.Drawing.Color]::LightGray 
$hr1.Location = New-Object System.Drawing.Point(8, 80) 

$hr2 = New-Object System.Windows.Forms.Label
$hr2.AutoSize = $false
$hr2.Height = 1 
$hr2.Width = 245
$hr2.BackColor = [System.Drawing.Color]::LightGray 
$hr2.Location = New-Object System.Drawing.Point(8, 165)

$form.Controls.Add($hr1)
$form.Controls.Add($hr2)

$estimateLabel = New-Object System.Windows.Forms.Label
$estimateLabel.Text = "Estimated run time: "
$estimateLabel.Location = New-Object System.Drawing.Point(110, 90)
$estimateLabel.AutoSize = $true
$form.Controls.Add($estimateLabel)

# Option label
$optionLabel = New-Object System.Windows.Forms.Label
$optionLabel.Text = "Select a command"
$optionLabel.Location = New-Object System.Drawing.Point(10, 90)
$optionLabel.AutoSize = $true
$form.Controls.Add($optionLabel)

# Option dropdown
$optionDropdown = New-Object System.Windows.Forms.ComboBox
$optionDropdown.Location = New-Object System.Drawing.Point(10, 108)
$optionDropdown.Size = New-Object System.Drawing.Size(180, 29)
$optionDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$optionDropdown.Items.AddRange($options)
$optionDropdown.Items.AddRange($ris2options)
$optionDropdown.Add_DrawItem({
    param([object]$sender, [System.Windows.Forms.DrawItemEventArgs]$e)

    $e.DrawBackground()
    $e.DrawFocusRectangle()
})
$optionDropdown.MaxDropDownItems = $options.Count + $ris2options.Count
$optionDropdown.Add_SelectedIndexChanged({
    $command = $optionDropdown.SelectedItem

    if ($config.estimates_invalid_options.Contains($command)) {
        $estimateLabel.Text = ""
    } elseif ($estimates.$command."executionTime") {
        $estimateLabel.Text = "Estimated run time: $($estimates.$command."executionTime")"
    } else {
        $estimateLabel.Text = "Estimated run time: Unknown"
    }
})
$form.Controls.Add($optionDropdown)


# POS Label
$posLabel = New-Object System.Windows.Forms.Label
$posLabel.Text = "POS #"
$posLabel.Location = New-Object System.Drawing.Point(9, 140)
$posLabel.AutoSize = $true
$form.Controls.Add($posLabel)

# POS Selector
$posSelector = New-Object System.Windows.Forms.NumericUpDown
$posSelector.Location = New-Object System.Drawing.Point(47, 137)
$posSelector.Size = New-Object System.Drawing.Size(40,35)
$posSelector.Minimum = 0
$posSelector.Maximum = 5
$posSelector.Add_MouseWheel({
    param($sender, $e)
    $delta = [System.Math]::Sign($e.Delta)
    $sender.Value = [System.Math]::Max($sender.Minimum, [System.Math]::Min($sender.Maximum, $sender.Value + $delta))
    $e.Handled = $true
})
$form.Controls.Add($posSelector)

#IMC POS Button
$posIMCButton = New-Object System.Windows.Forms.Button
$posIMCButton.Text = "IMC"
$posIMCButton.Location = New-Object System.Drawing.Point(95, 135)
$posIMCButton.Size = New-Object System.Drawing.Size(45,23)
$posIMCButton.Add_Click({
    $Process = 'C:\PROGRA~2\Intel\INTELM~1\nw.exe'
    $KFile = "W:\HD\Brice\Dev\MoyerToolbox\bin\keys\ImcKey"
    $CFile = "W:\HD\Brice\Dev\MoyerToolbox\bin\keys\IMC"

    $K = Get-Content $KFile
    $PwSecure = Get-Content $CFile | ConvertTo-SecureString -Key $K 
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PwSecure)
    $ImcPw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    $ip = Get-POSIp
    if ($ip) {
        $ProcessArgs = "-host:$ip -user:admin -pass:$ImcPw -kvm"
        Start-Process $Process -ArgumentList $ProcessArgs        
    }
})
$form.Controls.Add($posIMCButton)

# RDC POS Button
$posRDCButton = New-Object System.Windows.Forms.Button
$posRDCButton.Text = "RDC"
$posRDCButton.Location = New-Object System.Drawing.Point(145, 135)
$posRDCButton.Size = New-Object System.Drawing.Size(45,23)
$posRDCButton.Add_Click({
    $ip = Get-POSIp
    if ($ip) {
        if ($Global:UserOptions.autologin) {Start-Process "cmdkey" "/generic:$ip /user:7-11\$env:USERNAME /pass:$Global:pass"}
        Start-Process "mstsc" "/v:$ip"     
    }
})
$form.Controls.Add($posRDCButton)

# RDC ADMIN POS Button
$posRDCAdminButton = New-Object System.Windows.Forms.Button
$posRDCAdminButton.Text = "RDC (Admin Login)"
$posRDCAdminButton.Location = New-Object System.Drawing.Point(95, 135)
$posRDCAdminButton.Size = New-Object System.Drawing.Size(125,23)
$posRDCAdminButton.Visible = $false
$posRDCAdminButton.Add_Click({
    $ip = Get-POSIp
    if ($ip) {
        Start-Process "cmdkey" "/generic:$ip /user:localhost\admin /pass:7-ElevenPOS"
        Start-Process "mstsc" "/v:$ip"            
    }
})
$form.Controls.Add($posRDCAdminButton)

# PSEXEC POS Button
$posPsexecButton = New-Object System.Windows.Forms.Button
$posPsexecButton.Text = "PsExec"
$posPsexecButton.Location = New-Object System.Drawing.Point(195, 135)
$posPsexecButton.Size = New-Object System.Drawing.Size(55,23)
$posPsexecButton.Add_Click({
    $ip = Get-POSIp
    if ($ip) {
        Start-Process $Global:psexecPath "\\$ip cmd"           
    }
})
$form.Controls.Add($posPsexecButton)


# Connect to Device Button
$connectToButton = New-Object System.Windows.Forms.Button
$connectToButton.Text = "Connect To Device"
$connectToButton.Size = New-Object System.Drawing.Size(80,35)
$connectToButton.Location = New-Object System.Drawing.Point(5, 175)
$connectToButton.Add_Click({
    Disable-Buttons
    ConnectTo-Device
    Enable-Buttons
})
$form.Controls.Add($connectToButton)

# Ping Button
$pingButton = New-Object System.Windows.Forms.Button
$pingButton.Text = "Continuous Ping"
$pingButton.Size = New-Object System.Drawing.Size(80,35)
$pingButton.Location = New-Object System.Drawing.Point(90, 175)
$pingButton.Add_Click({
    Disable-Buttons
    Get-DeviceForPing
    Enable-Buttons
})
$form.Controls.Add($pingButton)

# Ping Network Devices Button
$pingNetworkButton = New-Object System.Windows.Forms.Button
$pingNetworkButton.Text = "Test Devices on Network"
$pingNetworkButton.Size = New-Object System.Drawing.Size(80,35)
$pingNetworkButton.Location = New-Object System.Drawing.Point(175, 175)
$pingNetworkButton.Add_Click({
    Disable-Buttons
    Network-Check
    Enable-Buttons
})
$form.Controls.Add($pingNetworkButton)


######################
## COMMAND HANDLING ##
######################


# Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run"
$runButton.Location = New-Object System.Drawing.Point(195, 106)
$runButton.Width = 55
$runButton.Add_Click({

    Disable-Buttons

    $selectedOption = $optionDropdown.SelectedItem
    if (!$storeNumber) {
        Show-Error -message "Please enter a valid store number"
    } else {
        
        if ($storeNumber -ne $storeTextbox.Text) {
            $connectButton.PerformClick()
        }
        
        try {
            $startTime = Get-Date

            if ($selectedOption -eq "Validate XMLs") {
                
                ## VALIDATE PASSPORT XMLS
                Validate-XML

            } elseif ($selectedOption -eq "Serial ATG Test") {
                
                ## SERIAL TIDEL TEST

                $tidelResponse = Invoke-Command -ComputerName "$ipAddress" -ScriptBlock {
                    Set-Location "C:\Program Files\Store\Log\System\"
                    tidel > tidel.txt
                    Get-Content -Path 'C:\Program Files\Store\Log\System\tidel.txt'
                } -Credential $credentials


                $tidelTestForm = New-Object System.Windows.Forms.Form
                $tidelTestForm.Text = "Tidel Test"
                $tidelTestForm.Size = New-Object System.Drawing.Size(325, 250)

                $tidelTextBox = Form-TextBox $tidelResponse

                $tidelTestForm.Controls.Add($tidelTextBox)
                $tidelTestForm.Controls.Add((Form-CopyButton))

                $tidelTestForm.ShowDialog()
                $optionDropdown.Enabled = $true
                

            } elseif ($selectedOption -eq "Clean C:/ Drive") {
                ## CLEAN S DRIVE ##
                if (((New-Object System.Net.NetworkInformation.Ping).Send("$ipPrefix.10", 2000)).Status -eq "Success") {
                    Start-Process $psexecPath "\\s$storeNumber -c -f remotecleanc.bat cmd"
                } else {
                    $confirmation = [System.Windows.Forms.MessageBox]::Show("The ISP appears to be offline`nWould you like to attempt to run it anyways?",'','YesNo','Information')
                    if ($confirmation -eq "Yes") {
                        Start-Process $psexecPath "\\s$storeNumber -c -f remotecleans.bat cmd"
                    }
                }

            } elseif ($selectedOption -eq "Clean S:/ Drive") {
                
                ## CLEAN S DRIVE ##
                if (((New-Object System.Net.NetworkInformation.Ping).Send("$ipPrefix.10", 2000)).Status -eq "Success") {
                    Start-Process $psexecPath "\\s$storeNumber -c -f remotecleans.bat cmd"
                } else {
                    $confirmation = [System.Windows.Forms.MessageBox]::Show("The ISP appears to be offline`nWould you like to attempt to run it anyways?",'','YesNo','Information')
                    if ($confirmation -eq "Yes") {
                        Start-Process $psexecPath "\\s$storeNumber -c -f remotecleans.bat cmd"
                    }
                }

            } elseif ($selectedOption -eq "CServe...") {
                
                Cserve-Control

            } elseif ($selectedOption -eq "Network Check Tool") {

                RunNetworkCheckTools                
                
            } elseif ($selectedOption -eq "Ping Network Devices") {

                ## NETWORK CHECK ##
                
            
            } elseif ($selectedOption -eq "Show Device Bindings") {
                
                Show-DeviceBindings

            } elseif ($selectedOption -eq "Show All Interfaces") {
                
                $routerHeader = "Router Interfaces
-----------------"
                $switchHeader = "Switch Interfaces
-----------------"
                $router = Invoke-Expression "echo y | plink -pw $Global:pass $env:USERNAME@$ipPrefix.193 `"show interfaces descriptions`""
                $switch = Invoke-Expression "echo y | plink -pw $Global:pass $env:USERNAME@$ipPrefix.198 `"show interfaces descriptions`""
                $spacer = "`n`n`n"

                $tempFilePath = [System.IO.Path]::GetTempFileName()
                $routerHeader |  Set-Content -Path $tempFilePath
                $router | Add-Content -Path $tempFilePath
                $spacer | Add-Content -Path $tempFilePath
                $switchHeader | Add-Content -Path $tempFilePath
                $switch | Add-Content -Path $tempFilePath

                Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath

            
            } elseif ($selectedOption -eq "Reactivate WAP") {

                ## POWER CYCLE WAP
                Start-Process "plink" "-ssh $env:USERNAME@$firstThree.198 -pw $pass `"edit; deactivate poe interface ge-0/0/46; deactivate poe interface ge-0/0/47; commit confirmed 1`""                
                
            } elseif ($selectedOption -eq "RDC into POS [Admin]") {
                
                $ip = (Get-POSIp)
                if ($ip) {                    
                    if ($Global:ConversionStore) {
                        Start-Process "cmdkey" "/generic:$ip /user:localhost\admin /pass:7-ElevenPOS"
                    } else {
                        Start-Process "cmdkey" "/generic:$ip /user:localhost\admin /pass:7-Elevenpos"
                    }
                    Start-Process "mstsc" "/v:$ip"            
                }

            } elseif ($selectedOption -eq "View POS Files") {
                
                $ip = Get-POSIp
                if ($ip) {
                    Start-Process "explorer.exe" -ArgumentList "\\$ip\c$"
                }
            } elseif ($selectedOption -eq "View ISP Files") {

                Start-Process "explorer.exe" -ArgumentList "\\s$storeNumber\c$"


            } elseif ($selectedOption -eq "Fuel Status") {

                ## DEX FUEL STATUS
                if (Check-DEX) {
                    $response = Invoke-Expression "echo y | plink -i $binPath\keys\fuelserverprodkey.ppk fuelserver@$firstThree.203 curl --max-time 3 -X GET `"http://127.0.0.1:8095/restservices/dex/v1/pos/status`"" | ConvertFrom-Json
                    $fuelStatus = $($response | Format-Table pump, state -AutoSize | Out-String)
    
                    if (-not $Global:dexFuelStatusForm -or $Global:dexFuelStatusForm.IsDisposed) {
                        $Global:dexFuelStatusForm = New-Object System.Windows.Forms.Form
                        $Global:dexFuelStatusForm.Text = "DEX Fuel Status"
                        $Global:dexFuelStatusForm.Size = New-Object System.Drawing.Size(300, 400)
    
                        $Global:dexFuelStatusForm.Controls.Add((Form-TextBox $fuelStatus))
                        $Global:dexFuelStatusForm.Controls.Add((Form-CopyButton))
                    }
    
                    $Global:textBox.Text = $fuelStatus
                    if (-not $Global:dexFuelStatusForm.Visible) {
                        $Global:dexFuelStatusForm.Show()
                    }
                }

            } elseif ($selectedOption -eq "Smart Reload") {

                ## DEX SMART RESTART
                if (Check-DEX) {
                    $smartRestartBlock = {
                        param(
                            $binPath,
                            $firstThree,
                            $completemessage
                        )
                        Add-Type -AssemblyName PresentationFramework
                        $response = Invoke-Expression "echo y | plink -i $binPath\keys\fuelserverprodkey.ppk fuelserver@$firstThree.203 `"python /opt/apps/FCcontroller/deployment/dexrepo/scripts/dexsmartupdate.py restartonly`""
                        [System.Windows.MessageBox]::Show($completemessage, "MoyerToolbox")
                    }
                    
                    Start-Job -ScriptBlock $smartRestartBlock -ArgumentList $Global:binPath, $Global:firstThree, $Global:config.command_messages.dex_smart_reload_complete
    
                    Show-Info -message $config.command_messages.dex_smart_reload_start
                }
                

            } elseif ($selectedOption -eq "Force Reload") {

                ## DEX FORCE REBOOT
                if (Check-DEX) {
                    $forceRestartBlock = {
                        param(
                            $binPath,
                            $firstThree,
                            $completemessage
                        )
                        Add-Type -AssemblyName PresentationFramework
                        $response = Invoke-Expression "echo y | plink -i $Global:binPath\keys\fuelserverprodkey.ppk fuelserver@$Global:firstThree.203 `"cd /opt/apps/FCcontroller/bin; ./killprocess.sh; ./start.sh`""
                        [System.Windows.MessageBox]::Show($completemessage, "MoyerToolbox")
                    }
                    
                    Start-Job -ScriptBlock $forceRestartBlock -ArgumentList $Global:binPath, $Global:firstThree, $Global:config.command_messages.dex_force_reload
    
                    Show-Info -message "DEX Force Reload Started"
                }                
                
            } elseif ($selectedOption -eq "POS Logoff") {

                if ($posSelector.Value -eq 0 -or !$Ris20) {
                    $ip = Get-POSIp
                    if ($ip) {
                        Start-Process "$Global:psexecPath" "\\$ip logoff console"
                    }
                } else {
                    Invoke-Command -ComputerName (Get-POSIp) -ScriptBlock { logoff console } -Credential $Global:credentials
                    Show-Info -message "Logoff command was successful"

                }

            } elseif ($selectedOption -eq "Reimage POS") {

                if ($Global:ConversionStore) {
                    Show-Error -message "Reimaging POSs for Speedway Conversion stores will brick the POS. A replacement drive is required"
                } else {

                    if (Check-YesNo "Are you sure you want to reimage POS $($posSelector.Value)?" "POS Reimage Confirmation") {
                        if ($Ris20) {
                            $ip = Get-POSIp
                            if (Test-Path "\\$ip\t$\") {
                                if ($posSelector.Value -eq 0) {
                                    
                                    if ($ip) {
                                        Start-Process "$Global:psexecPath" "\\$ip -h powershell.exe -File c:\\necpos\\utils\\recoveryMode.ps1"
                                    }
                                } else {
                                    Invoke-Command -ComputerName ($ip) -ScriptBlock {                     
                                        Push-Location 'c:\necpos\utils\'
                                        $recoveryMode = .\recoveryMode.ps1 | Out-string 
                                    } -Credential $Global:credentials
                                } 
                            } else {
                                if (Check-YesNo "T:/ Drive seems to be mislabeled`n`nI can attempt an automatic correction, would you like me to try?" "T:/ Drive Mislabeled") {
                                    Invoke-Command -ComputerName $ip -ScriptBlock {
                                        Get-Partition -DriveLetter D | Set-Partition -NewDriveLetter T
                                    } -Credential $Global:credentials

                                    if (Test-Path "\\$ip\t$\Images") {
                                        Invoke-Command -ComputerName ($ip) -ScriptBlock {                     
                                            Push-Location 'c:\necpos\utils\'
                                            $recoveryMode = .\recoveryMode.ps1 | Out-string 
                                        } -Credential $Global:credentials
                                    } else {
                                        Show-Error -message "Hmm it seems the automatic correction failed, try manually logging into the POS and run the powershell command `n`nGet-Partition -DriveLetter D | Set-Partition -NewDriveLetter T"
                                    }
                                }
                            }
                            
                        } else {
                            Show-Error -message "Store is not RIS 2.0"
                        }
                    }
                }

            } elseif ($selectedOption -eq "POS Health Check") {

                if ($Ris20) {
                    if ($posSelector.Value -eq 0) {
                        Show-Error -message "Manual IP selection is not available for POS Health Check"
                    } else {
                        $ip = Get-POSIp
                        if ($ip) {
                            Run-PosHealthCheck -ip $ip
                        }
                    }
                } else {
                    Show-Error -message "Store is not RIS 2.0"
                }
            } elseif ($selectedOption -eq "ISP Check Tool") {

                if (Check-ISP) {
                    Run-ISPCheckTool
                }

            } elseif ($selectedOption -eq "Start BBU Relearn") {
                
                if (Check-ISP) {
                    Invoke-Command -ComputerName "$Global:ipAddress" -ScriptBlock { & MegaCli -AdpBbuCmd -BbuLearn -aAll } -Credential $Global:credentials -WarningAction Stop -ErrorAction Stop
                    Show-Info -message "BBU Relearn Cycle has started, this can take a few hours but monitoring is not needed"
                }
                
            } elseif ($selectedOption -eq "Get Store Config") {

                Get-StoreConfig

            } elseif ($selectedOption -eq "Show Users") {

                Get-Users

            } elseif ($selectedOption -eq "7MD Diagnostic") {

                Run-7MDDiag

            } elseif ($selectedOption -eq "POS Ports Check") {
                $ip = Get-POSIp
                if ($ip) {
                    CheckPorts -ipaddr $ip
                }
            } elseif ($selectedOption -eq "MOM Check") {

                if ($Ris20) {
                    $domain = "storesp.7-11.com"
                    $posIP = 1..4 | %{"$storeNumber-POS0$_.$domain"} | ?{Test-Connection $_ -Count 1 -Quiet} | select -First 1
        
                    if ($posIP -ne $null) {
                        Check-Mom -IP $posIP        
                    } else {
                        Show-Error -message "No POSs available"
                    }
                } else {
                    Check-Mom
                }
                
            } elseif ($selectedOption -eq "POS Version Audit") {

                if (!$Ris20) {
                    Show-Error -message "Not a 2.0 store"
                } else {
                    $ip = Get-POSIp
                    if ($ip) {
                        AuditPOSVersion -ip $ip
                    }
                }

            } elseif ($selectedOption -eq "Open TabaScope") {

                Start-process c:\progra~2\google\chrome\application\chrome.exe "https://d17ypxz75u0mbn.cloudfront.net/store/$storeNumber"

            } elseif ($selectedOption -eq "Therapy") {
                $url = "file:///W:/HD/Brice/Dev/MoyerToolbox/bin/Boop/boop%20reduxx2.html"
                Start-process c:\progra~2\google\chrome\application\chrome.exe $url
            } elseif ($selectedOption -eq "Show Message on POS") {

                $posMsgForm = New-Object System.Windows.Forms.Form
                $posMsgForm.Text = 'Message Input'
                $posMsgForm.Size = New-Object System.Drawing.Size(300,150)
                $posMsgForm.StartPosition = 'CenterScreen'

                $posMsgLabel = New-Object System.Windows.Forms.Label
                $posMsgLabel.Location = New-Object System.Drawing.Point(10,10)
                $posMsgLabel.Size = New-Object System.Drawing.Size(280,20)
                $posMsgLabel.Text = 'Enter message to show on POS:'
                $posMsgForm.Controls.Add($posMsgLabel)

                $posMsgTextBox = New-Object System.Windows.Forms.TextBox
                $posMsgTextBox.Location = New-Object System.Drawing.Point(10,40)
                $posMsgTextBox.Size = New-Object System.Drawing.Size(260,20)
                $posMsgForm.Controls.Add($posMsgTextBox)

                $posMsgOkButton = New-Object System.Windows.Forms.Button
                $posMsgOkButton.Location = New-Object System.Drawing.Point(10,70)
                $posMsgOkButton.Size = New-Object System.Drawing.Size(75,23)
                $posMsgOkButton.Text = 'OK'
                $posMsgOkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $posMsgForm.AcceptButton = $posMsgOkButton
                $posMsgForm.Controls.Add($posMsgOkButton)

                $posMsgForm.Topmost = $true
                $posMsgForm.Add_Shown({$posMsgForm.Activate()})
                $formresult = $posMsgForm.ShowDialog()

                if ($formresult -eq [System.Windows.Forms.DialogResult]::OK)
                {
                    $posMsgText = [string]$posMsgTextBox.Text
                    if (!($posMsgText -eq "")) {
                        $ip = Get-POSIp
                        if ($ip) {
                            & msg /server:$ip AUTOPOS $posMsgText
                        }
                    } else {
                        Show-Error -message "Message cannot be blank"
                    }
                    
                }
            } elseif ($selectedOption -eq "Reboot EDH") {

                ## REBOOT EDH
                if ($Ris20) {
                    Show-Error -message "Store is RIS 2.0, store does not have an EDH"
                } else {
                    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to reboot the EDH?`nThis will take the pinpads and fuel offline while it reboots`nThis usually takes 10 minutes", "EDH Reboot Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo)

                    if ($result -eq "Yes") {
                        $rebootCommandOutput = Invoke-Command -ComputerName "$ipPrefix.10" -ScriptBlock {         
                            & cserve stop fuel            
                            $output = & C:\PROGRA~1\STORE\ISP.APPLICATIONS\EDHUTIL /edhhost=passporteps /action=rebootedh        
                            if ([bool]($output -Match "\*\* Operation completed successfully \*\*")) {
                                Start-Job -ScriptBlock {
                                    Start-Sleep 720
                                    & cserve start fuel
                                }
                            } else {
                                & cserve start fuel
                            }
                            return $output
                        } -Credential $Global:credentials
                        
                        if ([bool]($rebootCommandOutput -Match "\*\* Operation completed successfully \*\*")) {
                            $eta = (Get-Date).AddMinutes(12).ToString("HH:mm")
                            Show-Info -message "EDH Reboot Command Send Successfully!`n`nEDH is currently rebooting. This can take around 10 minutes`nFuel services will be started automatically in 12 minutes [ETA: $eta]"
                        } elseif ([bool]($rebootCommandOutput -Match "Unable to connect to PSS Service")) {
                            Show-Error -message "EDH Reboot Command Failed to Send`n`nERROR: Unable to establish connection to EDH, make sure the EDH is online and try again"
                        } else {
                            Show-Error -message "EDH Reboot Command Failed to Send`n`Unknown Error:`n$rebootCommandOutput"
                        }
                    }
                    
                }
                
            } elseif ($selectedOption -eq "Reload EDH Config File") {

                ## UPDATE EDH CONFIGS
                if ($Ris20) {
                    Show-Error -message "Store is RIS 2.0, store does not have an EDH"
                } else {
                    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to reload the configuration for the EDH?`nThis will take the pinpads and fuel offline while it reboots`nThis usually takes 10 minutes", "EDH Reboot Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo)

                    if ($result -eq "Yes") {
                        $updateConfigCommandOutput = Invoke-Command -ComputerName "$ipPrefix.10" -ScriptBlock {
                            if (Test-Path "C:\Program Files\Store\Database\Fuel\EDHFuelApplicationState.xml.old") {
                                Remove-Item -Path "C:\Program Files\Store\Database\Fuel\EDHFuelApplicationState.xml.old"
                            }
                            if (Test-Path "C:\Program Files\Store\Database\Fuel\EDHFuelApplicationState.xml") {
                                Rename-Item -Path "C:\Program Files\Store\Database\Fuel\EDHFuelApplicationState.xml" "EDHFuelApplicationState.xml.old"
                                & cserve stop fuel
                                $rebootCommandOutput = & C:\PROGRA~1\STORE\ISP.APPLICATIONS\EDHUTIL /edhhost=passporteps /action=rebootedh
                                
                                if ([bool]($rebootCommandOutput -Match "\*\* Operation completed successfully \*\*")) {
                                    return 0
                                } elseif ([bool]($rebootCommandOutput -Match "Unable to connect to PSS Service")) {
                                    Rename-Item -Path "C:\Program Files\Store\Database\Fuel\EDHFuelApplicationState.xml.old" "EDHFuelApplicationState.xml"
                                    & cserve start fuel
                                    return 1
                                } else {
                                    Rename-Item -Path "C:\Program Files\Store\Database\Fuel\EDHFuelApplicationState.xml.old" "EDHFuelApplicationState.xml"
                                    & cserve start fuel
                                    return $rebootCommandOutput
                                }
                            } else {
                                return 2
                            }

                        } -Credential $Global:credentials

                        if ($updateConfigCommandOutput -eq 0) {
                            
                            Invoke-Command -ComputerName "$ipPrefix.10" -ScriptBlock {
                                Start-Sleep 720
                                & cserve start fuel
                            } -Credential $Global:credentials -AsJob

                            $eta = (Get-Date).AddMinutes(12).ToString("HH:mm")
                            Show-Info -message "EDH Config Reload Successful`n`nEDH is currently rebooting. This can take around 10 minutes.`nFuel services will be started automatically in 12 minutes [ETA: $eta]"
                        } elseif ($updateConfigCommandOutput -eq 1) {
                            Show-Error -message "EDH Config Reload Failed`n`nCould not connect to the EDH to initiate a reboot`nPlease make sure the EDH is online before attempting another config file reload"
                        } elseif ($updateConfigCommandOutput -eq 2) {
                            Show-Error -message "EDH Config Reload Failed`n`nFile 'EDHFuelApplicationState.xml' does not exist`nEnsure this is an EDH store and if so, attempt a normal EDH reboot"
                        } else {
                            Show-Error -message "EDH Config Reload Failed`n`nUnknown Error: $updateConfigCommandOutput"
                        }
                    }

                }
            } elseif ($selectedOption -eq "My Preferences...") {
                Show-OptionsPanel
            } elseif ($selectedOption -eq "Day Mapping Error Check") {

                if (Check-ISP) {
                    $errors = (cmd /c "echo select * from BUSINESS_DAY_SHIFT WHERE MAPPING_STATUS = 'M' order by day_nbr desc;|sqlplus RISSTORE/SevenReta11`$tore@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=s$storeNumber)(PORT=1573))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=RIS)))") -Split "\n" | Where-Object { $_ -match '^\s*\d[0-9]*' -or $_ -match "---" -or $_ -match "DAY_NBR"} | Out-String
                    if ($errors.Length) {
                        Show-Error -message "Day Mapping Error Found"

                        $tempFilePath = [System.IO.Path]::GetTempFileName()
                        "Day Mapping Error Detected`nPaste this into the ticket and assign to RIS - PRODSUP for correction`n`n" | Set-Content -Path $tempFilePath
                        $errors | Add-Content -Path $tempFilePath

                        Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath
                    } else {
                        Show-Info -message "No Day Mapping Errors Found"
                    }
                }

            } elseif ($selectedOption -eq "Get Recent POS Transactions") {

                . "$binPath\getPOSTransactions.ps1"
                if ($Ris20) {
                    Get-POSTransactions

                } else {
                    Show-Error -message "This function is currently only available at 2.0 locations, a 1.0 version is currently in development"
                }

            } elseif ($selectedOption -eq "Show Policies") {

                $policies = Router-Plink -command "show configuration | display set | match chrom | count;show configuration | display set | match chrom"

                $tempFilePath = [System.IO.Path]::GetTempFileName()
                $policies| Set-Content $tempFilePath
                Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath

            } elseif ($selectedOption -eq "Interim ISP Check") {

                if (Check-ISP) {
                    if (Test-Path "\\s$storeNumber\c$") {
                        if (Test-Path "\\s$storeNumber\c$\Program Files\MegaRAID Storage Manager\startupui.bat") {
                            Show-Info -message "ISP is not an interim`nReason: MegaRAID is present"
                        } else {
                            Show-Info -message "ISP is an interim`nReason: MegaRAID is not present"
                        }
                    } else {
                        Show-Error -message "Unable to access ISP, cannot determine ISP type"
                    }
                    
                }
            } elseif ($selectedOption -eq "DEX Forecourt Status") {
                Get-ForeCourtStatus
            }

            $executionTime = (Get-Date) - $startTime
            if ($selectedOption -ne "") {
                "$selectedOption|$($executionTime.TotalSeconds)" | Add-Content -Path "$binPath\commandExecutionTimes.txt"
            }

            # 5% chance to process telemetry
            if ((Get-Random -Minimum 1 -Maximum 21) -eq 1) {
                Start-TelemetryProcessing
            }

        } catch {
            Show-Error -message "Failed to run $selectedOption`: `n`nLine: $($_.InvocationInfo.ScriptLineNumber) `nError: $_"
            Write-Host "Failed to run $selectedOption`: `n`nLine: $($_.InvocationInfo.ScriptLineNumber) `nError: $_"
        }
    }
    
    Enable-Buttons
})
$form.Controls.Add($runButton)


$contextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
$principalContext = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $contextType
$isValid = $false
$attemptCount = 0

$isValid = $false

if ($PSScriptRoot -Match "\\DevBox\\") {
    if (!($env:USERNAME -Match 'bmoy3001')) {
        Show-Error -message "Unauthorized user detected exiting script"
        exit
    }
}

while (-not $isValid -and $attemptCount -lt 3) {
    $attemptCount++
    $Global:credentials = Get-Credential $env:USERNAME

    if ($null -eq $Global:credentials) {exit}

    $Global:username = $env:USERNAME
    $Global:pass = $credentials.GetNetworkCredential().Password

    if ($Global:pass -eq "") {
        Show-Error -message "Password cannot be blank. Please try again."
        continue
    }

    $isValid = $principalContext.ValidateCredentials($Global:username, $Global:pass)

    if (-not $isValid) {
        Show-Error -message "Invalid password. Please try again."
    }
}

if ($attemptCount -ge 3) {
    Show-Error -message "Account authentication failed, please make sure your account is not locked"
    exit
}

if (Test-Path "$path\user_prefs\$(Hash-String($Global:username)).json") {
    $Global:UserOptions = Get-Content -Path "$path\user_prefs\$(Hash-String($Global:username)).json" | ConvertFrom-Json
} else {
    "{'autologin':1, 'autoclose_connectto': 1}" | Set-Content -Path "$path\user_prefs\$(Hash-String($Global:username)).json"
    $Global:UserOptions = Get-Content -Path "$path\user_prefs\$(Hash-String($Global:username)).json" | ConvertFrom-Json
}

$estimates = Get-TelemetryData

# Show the form
$form.ShowDialog() | Out-Null
