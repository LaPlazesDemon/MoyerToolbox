Add-Type -AssemblyName System.Windows.Forms

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


Function Validate-XML {
    try {

        $mostRecentXMLText
        $status = "PASSED"
        $errCount = 0
        $errorText = ""
        $warningText = ""

        #TESTING FOR EXISTENCE OF MSM AND MCM FILES
        Write-Debug "Retrieving XMLs"
        $msmFiles = @(Invoke-Command -ComputerName $Global:ipAddress -Credential $Global:credentials -ScriptBlock {(Get-ChildItem -Path "C:\Program Files\Store\3rdParty\PassportPOS\" -Filter "MSM*.xml" | Where-Object { $_.CreationTime -ge (Get-Date).AddDays(-1) })})
        $mcmFiles = @(Invoke-Command -ComputerName $Global:ipAddress -Credential $Global:credentials -ScriptBlock {(Get-ChildItem -Path "C:\Program Files\Store\3rdParty\PassportPOS\" -Filter "MCM*.xml" | Where-Object { $_.CreationTime -ge (Get-Date).AddDays(-1) })})
        Write-Host $msmFiles
        Write-Host $mcmFiles
        Write-Debug "Finished Retrieving XMLs"

        $msmExists = $msmFiles.Count -gt 0
        $mcmExists = $mcmFiles.Count -gt 0

        Write-Host $mcmExists
        Write-Host $msmExists

        if (!$msmExists -and !$mcmExists) {
            Write-Debug "Both XML types are missing"
            $errCount += 1
            $status = "FAILED"
            $mostRecentXML = Invoke-Command -ComputerName $Global:ipAddress -Credential $Global:credentials -ScriptBlock {(Get-ChildItem -Path "C:\Program Files\Store\3rdParty\PassportPOS\" -Filter "M*.xml" | Sort-Object CreationTime -Descending | Select-Object -First 1).CreationTime}
            if ($mostRecentXML) {
                $mostRecentXMLText = "Most Recent XMLs: $mostRecentXML"
                $errorText = "No XMLs were found for today$($nl)Most Recent XML: $mostRecentXML$($nl)$($nl)(If passport was just repaired then wait for the next day and rerun verification)"
            } else {
                $errorText = "No XMLs Were Found$($nl)$($nl)(If passport was just repaired then wait for the next day and rerun verification)"
            }
        } elseif ($msmExists) {
            Write-Debug "Found MSMs"
            ## Finding EOD File
            Write-Debug "Validating Data in XMLs"
            $result = Invoke-Command -ComputerName $Global:ipAddress -Credential $Global:credentials -ScriptBlock {

                $xmlFiles = Get-ChildItem -Path "C:\Program Files\Store\3rdParty\PassportPOS\" -Filter "MSM*.xml" | Where-Object { $_.CreationTime -ge (Get-Date).AddDays(-1) }
                $eodFile = $false
                $shift1File = $false
                $errorsFound = 0
                $returnText = ""
                $warningText = ""
                $nl = "
"
                $passportVersion = ""

                foreach ($file in $xmlFiles) {
                    if ($null -ne $file) {

                        $fileErrors = ""
                        $xmlFile = Get-Content -Path "C:\Program Files\Store\3rdParty\PassportPOS\$file"
                        $xmlContent = [xml]$xmlFile
                        $PRP = $xmlContent.'NAXML-MovementReport'.MiscellaneousSummaryMovement.MovementHeader.PrimaryReportPeriod
                        $SRP = $xmlContent.'NAXML-MovementReport'.MiscellaneousSummaryMovement.MovementHeader.SecondaryReportPeriod
                        $passportVersion = $xmlContent.'NAXML-MovementReport'.TransmissionHeader.VendorModelVersion

                        if ($xmlFile -match "<!DOCTYPE") {

                            Write-Host "Found "
                            ##DOCTYPE FOUND IN XML
                            $errorsFound += 1
                            $status = "FAILED"
                            $fileErrors += "<!DOCTYPE> Tag Found in XML"

                        } elseif ($PRP -eq "2") {
                            
                            # EOD Report
                            $eodFile = $true
                            if ($SRP -ne 0) {
                                $errorsFound += 1
                                $status = "FAILED"
                                $fileErrors += "Shift number exists in EOD report"
                            }

                        } elseif ($PRP -eq "1") {
                            
                            # EOS Report
                            if ($SRP -eq 1) {$shift1File = $true}
                            elseif ($SRP -eq 2) {}
                            elseif ($SRP -eq 3) {}
                            elseif ($SRP -eq 4) {$warningText = "WARNING: 4th Shift XML is present, store may have ran an extra EOS"}
                            else {
                                $errorsFound += 1
                                $status = "FAILED" 
                                $fileErrors += "Unknown Shift Error$($nl)Shift Number: $SRP $($nl)"
                            }
                        } elseif ($PRP -eq 98) {
                            $errorsFound += 1
                            $status = "FAILED"
                            $fileErrors += "ERROR 98$($nl)Primary Period: $PRP "
                        } elseif ($null -eq $PRP) {
                            $errorsFound += 1
                            $status = "FAILED"
                            $fileErrors += "Primary Period: Unknown"
                        } else {
                            $errorsFound += 1
                            $status = "FAILED"
                            $returnText += "Primary Period: $PRP"
                        }

                        if ($fileErrors -ne "") {
                            $returnText += "Data Validation Failure$nl$fileErrors$($nl)File: $file$nl$nl"
                        }
                    }
                }

                if (!$eodFile) {
                    $errorsFound += 1
                    $status = "FAILED"
                    $returnText += "EOD File Missing$($nl)$($nl)"
                } elseif (!$shift1File) {
                    $errorsFound += 1
                    $status = "FAILED"
                    $returnText += "1st Shift File Missing$($nl)$($nl)"
                }

                return @{
                    status = $status
                    errorText = $returnText
                    warningText = $warningText
                    version = $passportVersion
                    errCount = $errorsFound
                }
            }
            Write-Debug "Data Validation Completed"

            if ($result.status -eq "FAILED") {$status = "FAILED"}
            if (!$mcmExists) {$errorText += "FAILED: MCM Files Not Found$($nl)"}
            if ($result.errCount -gt 0) {$errorText += "$($result.errorText)Attach to ticket and speak with a Team Lead or a PASSPORT SME"}

            $warningText = $result.warningText
            $errCount += $result.errCount


        } else {
            if (!$msmExists) {$errorText = "FAILED: MSM Files Not Found$($nl)"}
            if (!$mcmExists) {$errorText += "FAILED: MCM Files Not Found$($nl)"}
            $status = "FAILED"
            $errorText += "$($nl)Files are missing$($nl)Attach to ticket and speak with a Team Lead or a PASSPORT SME"
        }

        if ($status -eq "PASSED") {
            [System.Windows.Forms.MessageBox]::Show("Passport XMLs Verification: PASSED", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            $passportResponse = "PASSPORT XML VALIDATION: FAILED
ERRORS FOUND: $errCount
PASSPORT VERSION: $($result.version)

$errorText
$warningText"
            $textBoxSize = 150+[int]$errCount*75
            $passportForm = New-Object System.Windows.Forms.Form
            $passportForm.Text = "Passport XML Validation"
            $passportForm.Size = New-Object System.Drawing.Size(350, $textBoxSize)
            $textBox.AutoSize = $true
            $textBox.Text = $passportResponse
            $passportForm.Controls.Add($textBox)
            $passportForm.Controls.Add($copyButton)
            $passportForm.ShowDialog()    
        }
    } catch {
        Show-Error -message "An unknown error occurred while performing XML validation$($nl)Please Try Again"
    }
        
}