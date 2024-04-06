Function Show-OptionsPanel {

    Write-Host $Global:UserOptions

    $currentPreferences = Get-Content -Path "$path\user_prefs\$(Hash-String($Global:username)).json" | ConvertFrom-Json
    
    $optionsPanel = New-Object System.Windows.Forms.Form
    $optionsPanel.Text = "Moyer Toolbox - Options"
    $optionsPanel.Size = New-Object System.Drawing.Size(275, 125)
    $optionsPanel.StartPosition = "CenterScreen"
    $optionsPanel.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $optionsPanel.MaximizeBox = $false;
    $optionsPanel.MinimizeBox = $false;

    $autoLoginLabel = New-Object System.Windows.Forms.Label
    $autoLoginLabel.Text = "Auto Login to Devices: "
    $autoLoginLabel.Font = New-Object System.Drawing.Font($autoLoginLabel.Font.FontFamily, 12)
    $autoLoginLabel.AutoSize = $true
    $autoLoginLabel.Location = New-Object System.Drawing.Point(10, 10)

    $autoLoginBox = New-Object System.Windows.Forms.CheckBox
    $autoLoginBox.Location = New-Object System.Drawing.Point(225, 10)
    $autoLoginBox.Checked = $currentPreferences.autologin

    $autoCloseConnectToLabel = New-Object System.Windows.Forms.Label
    $autoCloseConnectToLabel.Text = "Auto Close Connect To:"
    $autoCloseConnectToLabel.Location = New-Object System.Drawing.Point(10, 40)
    $autoCloseConnectToLabel.Font = New-Object System.Drawing.Font($autoCloseConnectToLabel.Font.FontFamily, 12)
    $autoCloseConnectToLabel.AutoSize = $true

    $autoCloseConnectToBox = New-Object System.Windows.Forms.CheckBox
    $autoCloseConnectToBox.Checked = $currentPreferences.autoclose_connectto
    $autoCloseConnectToBox.Location = New-Object System.Drawing.Point(225, 40)

    $optionsPanel.Controls.Add($autoLoginLabel)
    $optionsPanel.Controls.Add($autoLoginBox)
    $optionsPanel.Controls.Add($autoCloseConnectToLabel)
    $optionsPanel.Controls.Add($autoCloseConnectToBox)

    $optionsPanel.ShowDialog() | Out-Null

    "{'autologin': $([int]$autoLoginBox.Checked), 'autoclose_connectto': $([int]$autoCloseConnectToBox.Checked)}" | Set-Content -Path "$path\user_prefs\$(Hash-String($Global:username)).json"
    $Global:UserOptions = Get-Content -Path "$path\user_prefs\$(Hash-String($Global:username)).json" | ConvertFrom-Json

    Write-Host $Global:UserOptions

}