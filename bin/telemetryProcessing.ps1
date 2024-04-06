Function Start-TelemetryProcessing {

    Write-Host "Telemetry Processing Lottery Triggered"

    # Start-Job -ScriptBlock {

        Write-Host "Reading raw telemetry data"
        $telemetryDataRaw = @{}
        $telemetryFilePath = "$Global:binPath\commandExecutionTimes.txt"
        $telemetryFileData = (Get-Content -Path $telemetryFilePath) -Split "\n"
        Write-Host "Finished reading raw telemetry data"

        Write-Host "Extracting raw data"
        foreach ($telemetryFileEntry in $telemetryFileData) {

            $splitTelemetryEntry = ([string]$telemetryFileEntry) -Split "\|"
            Write-Host "Processing $splitTelemetryEntry"
            $command = $splitTelemetryEntry[0]
            $executionTime = $splitTelemetryEntry[1]

            if ($command) {
                if ($invalidOptions.Contains($command)) {
                    if (!$telemetryDataRaw[($command)]) {$telemetryDataRaw[($command)] = @{"executionTimes"  = @();"timesUsed" = 0}}
                    $telemetryDataRaw[($command)]["executionTimes"] += [double]$executionTime
                    $telemetryDataRaw[($command)]["timesUsed"] += 1
                }
            }
        }
        Write-Host "Finished extracting raw data"
        Write-Host ($telemetryDataRaw | ConvertTo-Json)
        $processedTelemetryData = @{}


        Write-Host "Processesing raw data"
        foreach ($command in $telemetryDataRaw.Keys) {
            
            Write-Host "$command average execution time calculated at $(($telemetryDataRaw[$command]["executionTimes"] | Measure-Object -Average).Average) seconds"
            $roundedAverage = [Math]::Round(($telemetryDataRaw[$command]["executionTimes"] | Measure-Object -Average).Average)

            if ($roundedAverage -gt 60) {
                $averageString = "$([Math]::Round($roundedAverage/60)) min"
            } else {
                $averageString = "$roundedAverage sec"
            }

            $processedTelemetryData[$command] =  @{
                "executionTime" = $averageString
                "timesUsed" =  $telemetryDataRaw[$command]["timesUsed"]
            }
        }
        Write-Host "Finished processesing raw data"

        $processedTelemetryData | ConvertTo-Json | Set-Content "$Global:binPath\processedTelemetry.json"
        Write-Host "Finished Telemetry Processing, Writing $(($processedTelemetryData|ConvertTo-Json).Length) Bytes"

    # }
}

Function Get-TelemetryData {

    $telemetryData = (Get-Content -Path "$Global:binPath\processedTelemetry.json") | ConvertFrom-Json
    return $telemetryData

}