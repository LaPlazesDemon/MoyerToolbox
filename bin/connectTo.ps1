Add-Type -AssemblyName System.Windows.Forms

$ping = New-Object System.Net.NetworkInformation.Ping
$timeout = 1000

Function ConnectTo-Device {
    $Global:connectForm = New-Object System.Windows.Forms.Form
    $connectForm.Text = "Connect to..."
    $connectForm.MaximizeBox = $false;
    $connectForm.MinimizeBox = $false;
    $connectForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $connectForm.Size = New-Object System.Drawing.Size(260,255)
    $connectForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $connectForm.Icon = $Global:formIcon;

    $routerButton = New-Object System.Windows.Forms.Button
    $routerButton.Text = "Router"
    $routerButton.Location = New-Object System.Drawing.Point(15,10)
    $routerButton.Size = New-Object System.Drawing.Size(100, 35)
    $routerButton.Add_Click({
        ## PuTTY Router ##
        if ($Global:UserOptions.autologin) {
            Start-Process "putty" "$firstThree.193 -l $env:USERNAME -pw $Global:pass"
        } else {
            Start-Process "putty" "$firstThree.193"
        }
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    $switchButton = New-Object System.Windows.Forms.Button
    $switchButton.Text = "Switch"
    $switchButton.Location = New-Object System.Drawing.Point(125, 10)
    $switchButton.Size = New-Object System.Drawing.Size(100,35)
    $switchButton.Add_Click({
        ## PuTTY Switch ##
        if ($Global:UserOptions.autologin) {
            Start-Process "putty" "$firstThree.198 -l $env:USERNAME -pw $Global:pass"     
        } else {
            Start-Process "putty" "$firstThree.198"
        }   
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    $ispButton = New-Object System.Windows.Forms.Button
    if ($Global:ConversionStore) {
        $ispButton.Text = "RDC DNS/DHCP"
    } else {
        $ispButton.Text = "RDC ISP"
    }
    $ispButton.Location = New-Object System.Drawing.Point(15,50)
    $ispButton.Size = New-Object System.Drawing.Size(100,35)
    $ispButton.Add_Click({
        ## RDC INTO THE ISP ##
        if ($Global:UserOptions.autologin) {Start-Process "cmdkey" "/generic:s$storeNumber /user:7-11\$env:USERNAME /pass:$Global:pass"}
        Start-Process "mstsc" "/v s$storeNumber"  
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    $psexecButton = New-Object System.Windows.Forms.Button
    if ($Global:ConversionStore) {
        $psexecButton.Text = "PsExec DNS/DHCP"
    } else {
        $psexecButton.Text = "PsExec ISP"
    }
    $psexecButton.Location = New-Object System.Drawing.Point(125, 50)
    $psexecButton.Size = New-Object System.Drawing.Size(100,35)
    $psexecButton.Add_Click({
        ## PSEXEC INTO ISP ##
        Start-Process $Global:psexecPath "\\s$storeNumber cmd"
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    $7RiseButton = New-Object System.Windows.Forms.Button
    $7RiseButton.Text = "7Rise"
    $7RiseButton.Location = New-Object System.Drawing.Point(15,90)
    $7RiseButton.Size = New-Object System.Drawing.Size(100,35)
    $7RiseButton.Add_Click({
        ## 7RISE ON TO THE ISP ##
        if ($Global:UserOptions.autologin) {Start-Process "cmdkey" "/generic:s$storeNumber /user:7-11\$env:USERNAME /pass:$Global:pass"}
        # New-Item -ItemType Directory -Force -Path "\\s$storeNumber\c$\Documents and Settings\$env:USERNAME.7-11\Start Menu\Programs\Startup\"
        # New-Item -ItemType Directory -Force -Path "\\s$storeNumber\c$\Documents and Settings\$env:USERNAME\Start Menu\Programs\Startup\"
        Copy-Item -Path "$binPath\Launch7Rise.bat" -Destination "\\s$storeNumber\c$\Documents and Settings\$env:USERNAME.7-11\Start Menu\Programs\Startup\"
        Copy-Item -Path "$binPath\Launch7Rise.bat" -Destination "\\s$storeNumber\c$\Documents and Settings\$env:USERNAME\Start Menu\Programs\Startup\"

        Start-Process "mstsc" "/v s$storeNumber"  
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    $7bossButton = New-Object System.Windows.Forms.Button
    $7bossButton.Text = "7BOSS"
    $7bossButton.Location = New-Object System.Drawing.Point(125,90)
    $7bossButton.Size = New-Object System.Drawing.Size(100,35)
    $7bossButton.Add_Click({
        ## OPEN 7BOSS
        $String = '{"storeId":"' + $Global:storeNumber + '","deviceType":"ISP"}'
		$ENCODED = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($String))
		$BossUrl = '"https://portal.ris.7-eleven.com/7boss/launch/storelogin/' + $ENCODED + '"'
		Start-process c:\progra~2\google\chrome\application\chrome.exe $BossUrl
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    $atgButton = New-Object System.Windows.Forms.Button
    $atgButton.Text = "Telnet ATG"
    $atgButton.Location = New-Object System.Drawing.Point(15, 130)
    $atgButton.Size = New-Object System.Drawing.Size(100,35)
    $atgButton.Add_Click({
        ## CONNECT TO ATG
        Start-Process "putty" "$firstThree.7 -telnet -P 10001"
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

   

    $dexButton = New-Object System.Windows.Forms.Button
    $dexButton.Text = "PuTTY DEX"
    $dexButton.Location = New-Object System.Drawing.Point(125,130)
    $dexButton.Size = New-Object System.Drawing.Size(100,35)
    $dexButton.Add_Click({
        ## PUTTY INTO DEX
        Start-Process "putty" "-i .\bin\keys\supportprodkey.ppk support@$firstThree.203"
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    $bmcButton = New-Object System.Windows.Forms.Button
    $bmcButton.Text = "Open BMC"
    $bmcButton.Location = New-Object System.Drawing.Point(15, 170)
    $bmcButton.Size = New-Object System.Drawing.Size(100,35)
    $bmcButton.Add_Click({
        ## CONNECT TO BMC
        Start-Process "C:\Program Files\Internet Explorer\iexplore.exe" -ArgumentList https://$firstThree.5
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    $printerButton = New-Object System.Windows.Forms.Button
    $printerButton.Text = "Lexmark Printer"
    $printerButton.Location = New-Object System.Drawing.Point(125,170)
    $printerButton.Size = New-Object System.Drawing.Size(100,35)
    $printerButton.Add_Click({
        ## OPEN Lexmark Managment
		$url = "http://$ipPrefix.179"
		Start-process c:\progra~2\google\chrome\application\chrome.exe $url
        if ($Global:UserOptions.autoclose_connectto) {$connectForm.Close()}
    })

    if ($Global:ConversionStore) {
        $bmcButton.Enabled = $false
        $switchButton.Enabled = $false
        $routerButton.Enabled = $false
    }

    $connectForm.Controls.Add($7bossButton)
    $connectForm.Controls.Add($7RiseButton)
    $connectForm.Controls.Add($dexButton)
    $connectForm.Controls.Add($atgButton)
    $connectForm.Controls.Add($bmcButton)
    $connectForm.Controls.Add($psexecButton)
    $connectForm.Controls.Add($ispButton)
    $connectForm.Controls.Add($switchButton)
    $connectForm.Controls.Add($routerButton)
    $connectForm.Controls.Add($printerButton)
    $connectForm.Show() | Out-Null
}