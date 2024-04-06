Function AuditPOSVersion {
    PARAM(
        [Parameter(Mandatory = $true)]
        [string]$ip
    )

    $tempFilePath = [System.IO.Path]::GetTempFileName()

    $output = Invoke-Command -ComputerName $ip -ScriptBlock {
        Get-ChildItem -Path 'HKLM:SOFTWARE\7POS' -Recurse |
            foreach {Get-ItemProperty -Path $_.PSpath} |
            select -Property * -ExcludeProperty path,PSParentPath,type,Pspath,PSProvider
    }
     
    $output | Select-Object -Property PschildName,Version,ReleaseDate | Format-Table -AutoSize | Out-String | Set-Content -Path $tempFilePath
    Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath

}