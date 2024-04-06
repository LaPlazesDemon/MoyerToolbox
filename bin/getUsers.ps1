$ping = New-Object System.Net.NetworkInformation.Ping
$timeout = 2000

Function Get-Users {
    if ($Global:Ris20) {
        
        $script = {
            try {
                $Safelogs = Get-ChildItem -Path 'c:\711.Peripherals\Log\Safe\SafeServer*' |
                    Sort-Object -Property LastWriteTime |
                    Select-Object -Last 2
    
                $Edata = Select-String -Pattern 'EmployeeData>' -Path $Safelogs |
                    Select-Object Line, LineNumber, Path -Last 2 |
                    Sort-Object -Property LineNumber
    
                $ResponseNumber = Select-String -Pattern '<EmployeeDataResponse>' -Path $Safelogs |
                    Select-Object Line, LineNumber -Last 1
    
                if ($ResponseNumber) {
                    $Response = (Get-Content -Path $Safelogs)[($ResponseNumber.LineNumber)] -replace '\</?text\>', ''
                } else {
                    $Response = 'No Response found'
                }
    
                [xml]$Xml = (Get-Content -Path $Edata[0].Path)[($Edata.LineNumber[0] - 1)..($Edata.LineNumber[1])]
                $Employees = $Xml.EmployeeData.Employee | Select-Object Name, EmployeeType, PIN -Unique | Sort-Object -Property Name
    
                $SafeErrors = Select-String -Pattern 'corrupt|value.+Duplicate' -Path $Safelogs |
                    Select-Object Line -Last 1
    
                if ($SafeErrors) {
                    $SafeErrors = $SafeErrors.Line -replace '(.+)\s+end.+Text:(.+)','$1 $2'
                } else {
                    $SafeErrors = 'No Safe errors Found'
                }
        
                $Employees | Add-Member -MemberType NoteProperty 'Safe Error' $SafeErrors -ErrorAction SilentlyContinue
                $Employees | Add-Member -MemberType NoteProperty 'Response' $Response.Trim() -ErrorAction SilentlyContinue
    
                $Employees | Sort-Object -Property Name
            } catch {
                [PSCustomObject] @{
                    'Failed' = 'No Data in current log'
                    'Error' = $error[0].Exception
                }
            }
        }

        $computerName = "$Global:storeNumber-POS01.storesp.7-11.com"
        
        $InvokeParams = @{
            ComputerName  = $computerName
            ScriptBlock   = $script
            SessionOption = (New-PSSessionOption -NoMachineProfile)
            ErrorAction   = 0
        }
    
        # Execute Command
    
        $result = Invoke-Command @InvokeParams |
            Select-Object -Property * -ExcludeProperty `
            PSComputerName, RunspaceID, PSShowComputerName
    
        $users = $result | 
        Select-Object Name, EmployeeType, PIN |
        Where-Object { $_.Name -notin " 36 ", " 37 "," 38 ", " 39 ", " 40 " } |
        Sort-Object Name

        $output = "
        --=!! DO NOT COPY INTO WORK NOTES !!=--
"+($users | Format-Table -AutoSize | Out-String)
        

        $tempFilePath = [System.IO.Path]::GetTempFileName()
        $output | Set-Content $tempFilePath
        Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath

    } else {

        $lines = (cmd /c "echo SELECT SUBSTR(EMPLOYEE_NBR, 5) AS EMPLOYEE_NUMBER,EMPLOYEE_NAME,PASSWORD,SECURITY_LVL,CLASS_ID FROM EMPLOYEE_FILE_WRK WHERE EMPLOYEE_NBR NOT IN (36, 37, 38, 39, 40) ORDER BY EMPLOYEE_NBR ASC;|sqlplus RISSTORE/SevenReta11`$tore@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=s$Global:storeNumber)(PORT=1573))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=RIS)))") -Split "\n" | Where-Object { $_ -match '^\d{2}' } |  Out-String


        $header = "
                   --=!! DO NOT COPY INTO WORK NOTES !!=--

Employee Info                     PIN                 Security Level
-------------                     ---                 --------------"
        $tempFilePath = [System.IO.Path]::GetTempFileName()
        $header | Set-Content -Path $tempFilePath
        $lines | Add-Content -Path $tempFilePath
        Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath
    }
}