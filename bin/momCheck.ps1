Function Check-Mom {
    PARAM(
        [Parameter(Mandatory = $false)]
        [string]$IP

    )

    if ($Global:Ris20) {

        $ScriptBlock={
        $MomServerLog = 'C:\711.Peripherals\Log\MOM\MOMServer.log'
        $MomClientLog = 'C:\711.Peripherals\Log\MOM\MOMClient.log'

        $Header = select-string -Pattern 'GetDatafromMOM' -Path  $MomServerLog  |
        select line -last 1

        $Timestamp = $Header.line -replace '.+(\{\"messageheader.+)','$1' | 
        convertfrom-json |
            Select -ExpandProperty messageheader |
        select -expand timestamp

        $Timestamp = $Timestamp -replace '(\d\d-)(\d\d-)(.+)','$2$1$3'

        $Message = $Header.line -replace '.+(\{\"messageheader.+)','$1' |
        ConvertFrom-Json |
        Select -ExpandProperty messagebody |
        select -expand message



        try {

        $Mom = Get-Process -Name *Mom* -ea stop | select Description,Name,ProductVersion,StartTime

        } 
        catch {
        $Mom = 'Mom Server is not running'
        $Err = $true
        }

        if (-not $Err) {
        $Mom | Add-Member -Type NoteProperty 'LogTimeStamp' $Timestamp -PassThru |
            Add-Member -Type NoteProperty 'Status' $Message.status -PassThru |
            Add-Member -Type NoteProperty 'Message' $Message.errorMessge -PassThru |
            Add-Member -Type NoteProperty 'Last MO S/N' $Message.serialNumber -PassThru |
            Add-Member -Type NoteProperty 'Last MO Amount' $Message.issuedAmount -PassThru |
            Add-Member -Type NoteProperty 'Next MO S/N' $Message.nextDocumentSerialNumber -PassThru 
        } else {
        [pscustomobject][ordered]@{    
                'Description'    = 'Mom Server is not running'
                'Name'          = 'COMMomServer is not running'
                'ProductVersion' = ''
                'StartTime'     = ''
                'LogTimeStamp'  = $Timestamp
                'Status'        = $Message.status
                'Message'        =$Message.errorMessge
                'Last MO S/N' =  $Message.serialNumber 
                'Last MO Amount' = $Message.issuedAmount 
                'Next MO S/N' = $Message.nextDocumentSerialNumber

        }
        }

        } # End Scriptblock


        try {
            
            if ($IP -notmatch 'POS') {
                $Ip = (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ip -ea stop).name.tostring()
            }

            $TempFile = [System.IO.Path]::GetTempFileName() + ".txt"
            
            $InvokeParams = @{
                ComputerName     = $Ip
                ScriptBlock      = $ScriptBlock
                SessionOption    = (New-PSSessionOption -NoMachineProfile)
                ErrorAction      = 'Stop'
            }
        
            # Execute Command and redirect output to temporary text file
            $result = Invoke-Command @InvokeParams |
                Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceID, PSShowComputerName | Out-File -FilePath $TempFile -Force
        
            # Open output file in Notepad.exe
            Start-Process notepad.exe $TempFile -Wait
        
            $result
        } catch {
            $Result = [pscustomobject][ordered]@{ 
                Result = "Could not run MOM check on $IP"
            }
            $error[0] | Show-Text
            $Result
        } finally {
            # Clean up: Delete temporary file after it's opened in Notepad
            Remove-Item -Path $TempFile -Force
        }
    } else {

        try {
            $TempFile = [System.IO.Path]::GetTempFileName()
            $Command = "$Global:psexecPath -w ""C:\capps\logs"" \\s$storeNumber cmd /c ""reg query HKLM\software\acs\mom && findstr /i ""Terminal"" logmomsrv* && pause"""
            
            # Execute the command and redirect output to temporary text file
            Invoke-Expression -Command $Command | Out-File -FilePath $TempFile -Force
        
            # Open output file in Notepad.exe
            Start-Process notepad.exe $TempFile
        } catch {
            Show-Error -message "Could not execute the command on server s$storeNumber.`nError: $_"
        }       
        
    }
}