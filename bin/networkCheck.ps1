Function Show-OutputTable {
    param (
        [Hashtable]$Data
    )
    $table = @()

    foreach ($attribute in $attributeOrder) {
        if ($data.ContainsKey($attribute)) {
            $customObject = New-Object PSObject
            $customObject | Add-Member -Type NoteProperty -Name "Attribute" -Value $attribute
    
            $orderedKeys = $data[$attribute].Keys | Sort-Object @{Expression={$_ -eq 'Flags'}; Ascending=$false}
            foreach ($innerKey in $orderedKeys) {
                $customObject | Add-Member -Type NoteProperty -Name $innerKey -Value $data[$attribute][$innerKey]
            }
    
            $table += $customObject
        }
    }

    $table | Format-Table -AutoSize
    $tableString = $table | Format-Table -AutoSize | Out-String

    $tempFilePath = [System.IO.Path]::GetTempFileName()
    $tableString | Set-Content -Path $tempFilePath

    Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath
}


Function RunNetworkCheckTools {

    ############
    ## ALARMS ##
    ############

    ## ROUTER ##

    $routerAlarmCmd = Router-Plink -command "show chassis alarms;show system alarms"
    $routerAlarm = $routerAlarmCmd -Split "\n"  
    $routerChaAlarmString = $routerAlarm[0]
    if ($routerAlarm[0] -eq "No alarms currently active") {
        $routerSysAlarmString = $routerAlarm[1]
    } else {
        $numOfRouterAlarms = [int]($routerChaAlarmString -Split " ")[0]
        $routerSysAlarmString = $routerAlarm[2+$numOfRouterAlarms]
    }

    ## SWITCH ##
    $switchAlarmCmd = Switch-Plink -command "show chassis alarms;show system alarms"
    $switchAlarm = $switchAlarmCmd -Split "\n"  
    $switchChaAlarmString = $switchAlarm[0]
    if ($switchAlarm[0] -eq "No alarms currently active") {
        $switchSysAlarmString = $switchAlarm[1]
    } else {
        $numOfSwitchAlarms = [int]($switchChaAlarmString -Split " ")[0]
        $switchSysAlarmString = $switchAlarm[2+$numOfSwitchAlarms]
    }

    ###################
    ## ENIRONMENTALS ##
    ###################


    ## ROUTER ##

    $routerEnv = Router-Plink -command "show chassis routing-engine;show chassis environment"
    $routerEnvSplit = $routerEnv -Split "\n"

    ##MODEL
    if ($routerEnv -match "SRX320") {$model = "320"} else {$model = "210"}
    if ($model -eq "320") {$routerModelSplit = $routerEnvSplit[12] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }} 
    else {$routerModelSplit = $routerEnvSplit[11] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }}
    $routerModelString = $routerModelSplit[1]

    ##LAST REBOOT REASON
    if ($model -eq "320") {$routerRebootReasonSplit = $routerEnvSplit[16] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }}
    else {$routerRebootReasonSplit = $routerEnvSplit[15] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }}
    $routerRebootReasonString = $routerRebootReasonSplit[3..($routerRebootReasonSplit.Length - 1)] -Join " "
    
    ##UPTIME
    if ($model -eq "320") {$routerUptimeSplit = $routerEnvSplit[15] -Split " "  | Where-Object { $_ -ne "" -and $_ -ne $null }} 
    else {$routerUptimeSplit = $routerEnvSplit[14] -Split " "  | Where-Object { $_ -ne "" -and $_ -ne $null }}
    $routerUptimeString = $routerUptimeSplit[1]+" "+($routerUptimeSplit[2].Substring(0, $routerUptimeSplit[2].Length - 1))

    ##TEMP
    $routerTempSplit = $routerEnvSplit[1] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $routerTempString = $routerTempSplit[1]+"°C"

    ##CPU
    if ($model -eq "320") {$routerCPUSplit = $routerEnvSplit[11] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }} 
    else {$routerCPUSplit = $routerEnvSplit[10] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }}
    $routerCPUString = ([string](100 - [int]($routerCPUSplit[1]))) + "%"

    ##MEMORY
    if ($model -eq "320") {$routerMemorySplit = $routerEnvSplit[3] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }}
    else {$routerMemorySplit = $routerEnvSplit[2] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }}
    $routerMemoryString = $routerMemorySplit[9]+"%"

    ##FAN1
    if ($model -eq "320") {
        $routerFan1Split = $routerEnvSplit[22] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
        $routerFan1String = ($routerFan1Split[6..($routerFan1Split.Length - 1)] -Join " ")
    }
    else {
        $routerFan1Split = $routerEnvSplit[21] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
        $routerFan1String = ($routerFan1Split[5..($routerFan1Split.Length - 1)] -Join " ")
    }

    ##FAN2
    if ($model -eq "320") {
        $routerFan2Split = $routerEnvSplit[23] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
        $routerFan2String = ($routerFan2Split[5..($routerFan2Split.Length - 1)] -Join " ")
    }


    ## SWITCH ##

    $switchEnv = Switch-Plink -command "show chassis routing-engine;show chassis environment"
    $switchEnvSplit = $switchEnv -Split "\n"

    ##MODEL
    $switchModelSplit = $switchEnvSplit[13] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $switchModelString = $switchModelSplit[1].Substring(0, $switchModelSplit[1].Length - 1)
    if ($switchModelString -match "EX2300") {
        $switchModel = "2300"
    } else {
        $switchModel = "2200"
    }
    
    ##LAST REBOOT REASON
    $switchRebootReasonSplit = $switchEnvSplit[17] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $switchRebootReasonString = $switchRebootReasonSplit[3..($switchRebootReasonSplit.Length - 1)] -Join " "

    ##UPTIME
    $switchUptimeSplit = $switchEnvSplit[16] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $switchUptimeString = $switchUptimeSplit[1]+" "+($switchUptimeSplit[2].Substring(0, $switchUptimeSplit[2].Length - 1))
    
    ##TEMP
    $switchTempSplit = $switchEnvSplit[3] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $switchTempString = " "+$switchTempSplit[1]+"°C"
    
    ##CPU
    $switchCPUSplit = $switchEnvSplit[12] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $switchCPUString = ([string](100 - [int]($switchCPUSplit[1]))) + "%"
    
    ##MEMORY
    $switchMemorySplit = $switchEnvSplit[6] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $switchMemoryString = $switchMemorySplit[2]+"%"
    
    ##FAN1
    if ($switchModel -eq "2300") {
        $switchFan1Split = $switchEnvSplit[24] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
        $switchFan1String = ($switchFan1Split[6..($switchFan1Split.Length - 1)] -Join " ")
    } else {
        $switchFan1Split = $switchEnvSplit[40] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
        $switchFan1String = ($switchFan1Split[6..($switchFan1Split.Length - 1)] -Join " ")
    }
    
    ##FAN2
    if ($switchModel -eq "2300") {
        $switchFan2Split = $switchEnvSplit[25] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
        $switchFan2String = ($switchFan2Split[5..($switchFan2Split.Length - 1)] -Join " ")
    } else {
        $switchFan2Split = $switchEnvSplit[41] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $switchFan2String = ($switchFan2Split[5..($switchFan2Split.Length - 1)] -Join " ")
    }
    
    ##FAN3
    try {
        $switchFan3Split = $switchEnvSplit[42] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
        $switchFan3String = ($switchFan3Split[5..($switchFan3Split.Length - 1)] -Join " ")
    } catch {}
    


    #######################
    ## STORAGE PARTITION ##
    #######################

    ## ROUTER ##
    $routerStorageCmd = Router-Plink -command "show system storage partitions"
    $routerStorage = $routerStorageCmd -Split "\n"
    $routerStorageLine = $routerStorage[3] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
    $routerStorageString = $routerStorageLine[3]

    ## SWITCH ##
    if ($switchModel -eq "2300") {
        $switchStorageString = "active"
    } else {
        $switchStorageCmd = Switch-Plink -command "show system storage partitions"
        $switchStorage = $switchStorageCmd -Split "\n"
        $switchStorageLine = $switchStorage[5] -Split " " | Where-Object { $_ -ne "" -and $_ -ne $null }
        $switchStorageString = $switchStorageLine[3]
    }


    ################
    ## CONFIGURED ##
    ################

    ## ROUTER ##
    $routerConfigCmd = Router-Plink -command "show system uptime | match configured"
    $routerConfigSplit = $routerConfigCmd -Split " " | Where-Object {$_ -ne "" -and $_ -ne $null}
    $routerConfigString = $routerConfigSplit[2]
    $routerConfigByString = $routerConfigSplit[($routerConfigSplit.Length - 1)]

    ## SWITCH ##
    $switchConfigCmd = Switch-Plink -command "show system uptime | match configured"
    $switchConfigSplit = $switchConfigCmd -Split " " | Where-Object {$_ -ne "" -and $_ -ne $null}
    $switchConfigString = $switchConfigSplit[2]
    $switchConfigByString = $switchConfigSplit[($switchConfigSplit.Length - 1)]

    ########################
    ## ACCESS POINT MODEL ##
    ########################
    
    
    ##FLAGS
    $chassisAlarmFlag;$systemAlarmFlag;$tempFlag;$memoryFlag;$storageFlag
    if ($routerChaAlarmString -ne "No alarms currently active" -or $switchChaAlarmString -ne "No alarms currently active") {$chassisAlarmFlag = "!!!"}
    if ($routerSysAlarmString -ne "No alarms currently active" -or $switchSysAlarmString -ne "No alarms currently active") {$systemAlarmFlag = "!!!"}
    if ($routerStorageString -ne "active" -or $switchStorageString -ne "active") {$storageFlag = "!!!"}
    if ([int]($routerTempSplit[1]) -gt 60 -or [int]($switchTempSplit[1]) -gt 60) {$tempFlag = "!!!"}
    if ([int]($switchMemorySplit[2]) -gt 90 -or [int]($routerMemorySplit[9]) -gt 90) {$memoryFlag = "!!!"}
    if ([int](100 - [int]($switchCPUSplit[1])) -gt 85 -or (100 - [int]($routerCPUSplit[1])) -gt 85) {$cpuFlag = "!!!"}

    $attributeOrder = "Model", "Partition", "Uptime", "Temperature", "CPU Usage", "Memory Usage", "Chassis Alarms", "System Alarms", "Last Configured", "Last Configured By", "Fan 1", "Fan 2", "Fan 3", "Reason for Last Reboot"
    $data = @{
        "Model" = @{
            Router = $routerModelString
            Switch = $switchModelString
            Flags = $null
        }
        "Partition" = @{
            Router = $routerStorageString
            Switch = $switchStorageString
            Flags = $storageFlag
        }
        "Uptime" = @{
            Router = $routerUptimeString
            Switch = $switchUptimeString
            Flags = $uptimeFlag
        }
        "Chassis Alarms" = @{
            Router = $routerChaAlarmString
            Switch = $switchChaAlarmString
            Flags = $chassisAlarmFlag
        }
        "System Alarms" = @{
            Router = $routerSysAlarmString
            Switch = $switchSysAlarmString
            Flags = $systemAlarmFlag
        }
        "Temperature" = @{
            Router = $routerTempString
            Switch = $switchTempString
            Flags = $tempFlag
        }
        "CPU Usage" = @{
            Router = $routerCPUString
            Switch = $switchCPUString
            Flags = $cpuFlag
        }
        "Memory Usage" = @{
            Router = $routerMemoryString
            Switch = $switchMemoryString
            Flags = $memoryFlag
        }
        "Fan 1" = @{
            Router = $routerFan1String
            Switch = $switchFan1String
            Flags = $fan1flag
        }
        "Fan 2" = @{
            Router = $routerFan2String
            Switch = $switchFan2String
            Flags = $fan2flag
        }
        "Fan 3" = @{
            Router = ""
            Switch = $switchFan3String
            Flags = $fan3flag
        }
        "Last Configured" = @{
            Router = $routerConfigString
            Switch = $switchConfigString
            Flags = $null
        }
        "Last Configured By" = @{
            Router = $routerConfigByString
            Switch = $switchConfigByString
            Flags = $null
        }
        "Reason for Last Reboot" = @{
            Router = $routerRebootReasonString
            Switch = $switchRebootReasonString
            Flags = $null
        }
    }

    Show-OutputTable -Data $data
}