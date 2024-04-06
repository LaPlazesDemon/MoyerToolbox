function CheckPorts {
    param(
        [string]$ipaddr
    )



    # Check if IP responds to ping
    if (Test-Connection -ComputerName $ipaddr -Count 1 -Quiet) {
        $targetPath = "\\$ipaddr\c$\necpos\UTILS\Enum_USBDEV_List.TXT"

        # Delete Enum_USBDEV_List.TXT if it exists
        if (Test-Path $targetPath) { Remove-Item -Path $targetPath -Force }

        # Execute USB Enumeration
        $argumentList = @("-c", "-f", "-w", "C:\necpos\UTILS", "\\$ipaddr", "W:\HD\Brice\Dev\MoyerToolbox\bin\USBEnum.exe")
        $process = Start-Process -FilePath $Global:psexecPath -ArgumentList $argumentList -Wait -PassThru
        $cmdError = $process.ExitCode

        Write-Host $cmdError
        if ($cmdError -ne 1) {
            Show-Error -message "POS Port Check Failed!"
        } else {

            $allContent = Get-Content -Path $targetPath

            $PinpadPattern = '^\[Port 01\.03\.01\]'
            $PrinterPattern = '^\[Port 01\.03\.02\.03\]'
            $ScannerPattern1 = '^\[Port 01\.06\]'
            $ScannerPattern2 = '^\[Port 01\.05\]'
            $ScannerPattern3 = '^\[Port 01\.03\.02\.02\]'
            $ScannerPattern4 = '^\[Port 01\.03\.02\.01\]'

            $PinpadString = $allContent | Select-String -Pattern $PinpadPattern
            $PrinterString = $allContent | Select-String -Pattern $PrinterPattern
            $ScannerString1 = $allContent | Select-String -Pattern $ScannerPattern1
            $ScannerString2 = $allContent | Select-String -Pattern $ScannerPattern2
            $ScannerString3 = $allContent | Select-String -Pattern $ScannerPattern3
            $ScannerString4 = $allContent | Select-String -Pattern $ScannerPattern4


            $lastPort = $null
            $failedPorts = @()

            # Read file line by line
            $allContent | ForEach-Object {
                # Check for [Port ...]
                if ($_ -match "\[Port .+?\]") {
                    $lastPort = $_
                }
                
                # Check for "FAILED !!! Bad USB Device"
                if ($_ -match "Bad USB Device") {
                    if ($lastPort -ne $null) {
                        $failedPorts += $lastPort
                    }
                }
            }

            $Content = "POS Port Checks For $ipaddr
Store: $Global:storeNumber

Pinpad
=----=
$PinpadString

Printer
=-----=
$PrinterString

Scanner
=-----=
$ScannerString1
$ScannerString2
$ScannerString3
$ScannerString4

Failed Ports
=----------=
$failedPorts"


            $tempFilePath = [System.IO.Path]::GetTempFileName()
            $Content | Set-Content -Path $tempFilePath
            # Open Notepad to display the log
            Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath
        }
    }
}