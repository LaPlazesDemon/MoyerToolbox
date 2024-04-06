$spacer = "
"
Function Get-POSTransactions {

    Function Start-GetJSONFileJob {
        param($filePath)

        return Start-Job -ScriptBlock {
            param($filePath)

            $jsonContent = Get-Content -Path $filePath | Out-String | ConvertFrom-Json 
            return $jsonContent

        } -ArgumentList $filePath

    }

    $detailedOutput = Check-YesNo "Do you want detailed payment outputs?" "Get Recent POS Transactions"

    $ip = Get-POSIp
    if ($ip) {

        # Test POS connectivity
        if (!(Test-Connection -ComputerName $ip -Count 1)) {
            Show-Error -message "Failed to get receipts from POS ($ip)`nPOS is offline"
        } else {

            #############
            ## RIS 2.0 ##
            #############

            # Check for Global Variable Ris 2.0
            if ($Ris20) {

                $receiptPath = "\\$ip\c$\7POS\Dataservice\receipts"

                # Check if the receipts folder exists and is accessible
                if (Test-Path $receiptPath) {

                    # Gets the most recent transactions from the POS excluding the last 2 (oldest 2) since these may become unavailable during execution
                    $receiptJSONs = Get-ChildItem -Path $receiptPath -Filter *.json | Sort-Object -Property LastWriteTime -Descending | Select-Object -SkipLast 2

                    Write-Host "Found $($receiptJSONs.Count) Receipts"

                    # Make sure there are receipts to scan
                    if ($receiptJSONs.Count) {

                        $receiptFileJobs = @{}

                        # Asynchronously read all the JSON files using Jobs
                        foreach ($receiptFile in $receiptJSONs) {
                            Write-Host "Starting JSON File Fetch Job for file '$receiptPath\$receiptFile'"
                            $receiptFileJobs[$receiptFile] = Start-GetJSONFileJob "$receiptPath\$receiptFile"
                        }

                        # Wait for all the read file jobs to complete
                        Write-Host "Waiting on all $($receiptFileJobs.Count) jobs to finish..."
                        $startWaitTime = Get-Date
                        $receiptFileJobs.Values | Wait-Job
                        $waitDuration = (Get-Date) - $startWaitTime
                        Write-Host "Waited $($waitDuration.TotalSeconds) seconds for all jobs to complete"

                        # Create temp file to store transaction data
                        $tempFilePath = [System.IO.Path]::GetTempFileName()
                        "Most Recent Transactions for $ip`n`n`n" | Set-Content -Path $tempFilePath

                        # Iterate through the receipts
                        foreach ($receiptFileJobKey in $receiptFileJobs.Keys) {

                            $receiptJSON = Receive-Job -job $receiptFileJobs[$receiptFileJobKey]
                            
                            Write-Host "Received JSON file contents from $receiptFileJobKey"

                            if (($receiptJSON.lineItem)) {
                                if ($receiptFileJobKey -match "TRN(\d+)_") {
                                    $transactionID = $matches[1]
                                } else {
                                    $transactionID = "Unknown"
                                }
                                "Transaction ID $transactionID $spacer`-------------------------" | Add-Content -Path $tempFilePath
    
                                # Iterate through items purchased
                                foreach ($lineItem in $receiptJSON.lineItem.items) {
                                    "$($lineItem.quantity)x $($lineItem.description) $($lineItem.details)"| Add-Content -Path $tempFilePath
                                }
    
                                "" | Add-Content -Path $tempFilePath
    
                                # Iterate through transaction totals
                                foreach ($lineTotal in $receiptJSON.transDetails.items) {
                                    "$($lineTotal.description) --> $($lineTotal.details)" | Add-Content -Path $tempFilePath
                                }
    
                                "" | Add-Content -Path $tempFilePath
    
                                if ($detailedOutput) {
                                    # Show detailed payment details by iterating through entire payment details
                                    foreach ($linePayment in $receiptJSON.paymentDetails.items) {
                                        "$($linePayment.description) $($linePayment.details)" | Add-Content -Path $tempFilePath
                                    }
                                } else {
                                    # Get first element of payment details (Payment type and amount)
                                    "$($receiptJSON.paymentDetails.items[0].description) $($receiptJSON.paymentDetails.items[0].details)" | Add-Content -Path $tempFilePath
                                }
                                
                                "$spacer"| Add-Content -Path $tempFilePath
                            }
                        }

                        Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath

                    } else {
                        Show-Error -message "Failed to get receipts from POS ($ip)`nNo receipts were found"
                    }
                } else {
                    Show-Error -message "Failed to get receipts from POS ($ip)`nFile path for receipts does not exist or is inaccessible"
                }
            } else {

                #############
                ## RIS 1.0 ##
                #############

                Show-Error -message "This function is currently only available at 2.0 locations, a 1.0 version is currently in development"
            }
        }
    }
}