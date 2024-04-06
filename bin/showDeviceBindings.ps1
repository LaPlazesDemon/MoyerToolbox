
Function Router-Plink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$command
    )
    $p = $Global:pass
    $u = "$env:USERNAME@$Global:firstThree.193"
    $response = Invoke-Expression "echo y | plink -pw $p $u `"$command`""
    return $response
}

Function Show-DeviceBindings {

    ############
    ## ROUTER ##
    ############

    $routerArpTable = Router-Plink -command "show arp;show dhcp server binding; ;show configuration system services dns dns-proxy cache"

    $tempFilePath = [System.IO.Path]::GetTempFileName()
    $routerArpTable | Set-Content -Path $tempFilePath

    Start-Process -FilePath "notepad.exe" -ArgumentList $tempFilePath
}