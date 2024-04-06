$nl = "
"
function Get-ForeCourtStatus {
    
    if (Check-DEX) {
        
        $forecourtJSON = ((Dex-Plink "grep -i -E 'DEX-STATUS\:' /opt/apps/FCcontroller/logs/FCAgent.log /opt/apps/FCcontroller/logs/FCcore.log /opt/apps/FCcontroller/logs/FCPayment.log | tail -10") -Split "DEX-STATUS:")[1] | ConvertFrom-JSON
        
        if (Check-YesNo "Do you want the raw JSON output?`nThis can help in finding values that are either missing or misidentified though, it makes reading the output more difficult") {
            
            ### Raw Ouput

            $tempFilePath = [System.IO.Path]::GetTempFileName()
            $forecourtJSON | ConvertTo-Json | Set-Content $tempFilePath
            Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath
        } else {

            ### Prettified/Formated Output

            $versionText = "DEX Software Version = $($forecourtJSON.version)"
            $storeDetailText = "State: $($forecourtJSON.storeAddress.State)$nl`City: $($forecourtJSON.storeAddress.City)$nl`Market #: $($forecourtJSON.storeAddress.storeMarketId)$nl`Store #: $($forecourtJSON.STOREID)$nl`RIS 2.0?: $($forecourtJSON.isRIS2Enabled)$nl`Fuel Brand: $($forecourtJSON.BRAND)/$($forecourtJSON.SUB_BRAND)"
            
            # Format the POS Status as a table
            $posStatusText = $forecourtJSON | 
            Select-Object -ExpandProperty posStatus | 
            Select-Object @{Name='POS'; Expression={$_.posNumber}}, @{Name='Can Reach?'; Expression={$_.posState}} |
            Format-Table -AutoSize |
            Out-String

            # Format the Payment Statuses as a table
            $paymentOptionsText = @(
                [PSCustomObject]@{"Payment Option" = "PATP Loyalty"; "Enabled?" = $forecourtJSON.loyaltyStatus.isPATPLoyaltyEnabled}
                [PSCustomObject]@{"Payment Option" = "Mobile Auth"; "Enabled?" = $forecourtJSON.loyaltyStatus.isMobileAuthEnabled}
                [PSCustomObject]@{"Payment Option" = "Post Payment Loyalty Prompt"; "Enabled?" = $forecourtJSON.loyaltyStatus.isPromptLoyaltyPostPayment}
            ) | 
            Select-Object "Payment Option", @{Name='Enabled?'; Expression={if ($_."Enabled?") {"Yes"} else {"No"}}} | 
            Format-Table -AutoSize | 
            Out-String

            # Format the Pump, Printer, CRIND Statuses as a table
            $generalPumpStatusTable = @()
            $crindsStatusTable = @()
            $pumpPrinterStatusTable = @()

            $forecourtJSON.forecourtStatus | ForEach-Object {
                $pumpNum = $_.pump
                $printerStatus = $forecourtJSON.printerStatus | Where-Object { $_.pumpId -eq $pumpNum }
                $crindsStatus = $forecourtJSON.EMVStatus | Where-Object { $_.crindId -eq $pumpNum }

                $generalPumpStatusTable += [PSCustomObject]@{
                    "Pump #" = $_.pump
                    "State" = $_.pumpState
                    "Status" = $_.icrState
                    "Pump BIOS" = $_.pumpBios
                    "Poll State" = $_.pumpPollState
                    "isHeadless" = $_.isHeadless
                }

                $pumpPrinterStatusTable += [PSCustomObject]@{
                    "Pump #" = $_.pump
                    "Printer State" = $printerStatus.printerState
                    "Printer Status" = $printerStatus.printerSubSt
                }

                $crindsStatusTable += [PSCustomObject]@{
                    "Pump #" = $pumpNum
                    "Status" = $crindsStatus.statemachineStatus
                    "Crind Type" = $_.crindType
                    "Crind BIOS" = $_.crindBios
                }
            }

            $miscStatusesTable = @(
                [PSCustomObject]@{System = "Carwash"; Status = $forecourtJSON.CarwashStatus; "Enabled?" = ""}
                [PSCustomObject]@{System = "EDIM"; Status = $forecourtJSON.EDIMSTATUS.edimState; "Enabled?" = $forecourtJSON.EDIMSTATUS.edimEnabled}
                [PSCustomObject]@{System = "EPS"; Status = $forecourtJSON.EPSSTATUS.epsState; "Enabled?" = $forecourtJSON.EPSSTATUS.epsEnabled}
                [PSCustomObject]@{System = "NODE"; Status = $forecourtJSON.NODESTATUS.nodeState; "Enabled?" = ""}
                [PSCustomObject]@{System = "Multiloop"; Status = $forecourtJSON.MULTILOOPSTATUS.multiLoop; "Enabled?" = ""}
            )

            # Only Speedway Conversions show the BIOS revision
            if ($ConversionStore) {
                $generalPumpStatusText = $generalPumpStatusTable | 
                Select-Object "Pump #", "State", "Status", "Pump BIOS",  @{Name='isHeadless'; Expression={if ($_."isHeadless") {"Yes"} else {"No"}}} | 
                Format-Table -AutoSize | 
                Out-String
            } else {
                $generalPumpStatusText = $generalPumpStatusTable | 
                Select-Object "Pump #", "State", "Status",  @{Name='isHeadless'; Expression={if ($_."isHeadless") {"Yes"} else {"No"}}} | 
                Format-Table -AutoSize | 
                Out-String
            }
            

            $pumpPrinterStatusText = $pumpPrinterStatusTable |
            Select-Object "Pump #", "Printer State", "Printer Status" |
            Format-Table -AutoSize |
            Out-String

            $crindStatusText = $crindsStatusTable | 
            Select-Object "Pump #", @{Name = "Crind Status";Expression = {if ($_.Status) {"Online"} else {"Offline"}}}, "Crind Type", "Crind BIOS" | 
            Format-Table -AutoSize | 
            Out-String

            $miscStatusesText = $miscStatusesTable | 
            Select-Object "System", "Status", @{Name="Enabled?"; Expression={if ($_."Enabled?" -eq "") {""} elseif ($_."Enabled?") {"Yes"} else {"No"}}} | 
            Format-Table -AutoSize | 
            Out-String

            $textoutput = "
DEX FORECOURT STATUS

$versionText

$storeDetailText

Note: POSs are based on IP even at RIS 2.0
POS # might not match up
$posStatusText$paymentOptionsText$generalPumpStatusText$pumpPrinterStatusText$crindStatusText$miscStatusesText
"
            $tempFilePath = [System.IO.Path]::GetTempFileName()
            "$textoutput" | Set-Content $tempFilePath
            Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath
        }

    }  
        
}