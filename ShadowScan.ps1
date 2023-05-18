param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$idFile,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ports
)

$ipAddresses = Get-Content $idFile

$aliveHosts = @()

Write-Host "Pinging hosts to check for alive hosts..."

foreach ($ip in $ipAddresses) {
    $result = Test-Connection -ComputerName $ip -Count 1 -Quiet
    if ($result) {
        $aliveHosts += $ip
        Write-Host "Host $ip is alive." -ForegroundColor Green
    } else {
        Write-Host "Host $ip is not responding." -ForegroundColor Red
    }
}

if ($aliveHosts.Count -eq 0) {
    Write-Host "No hosts are alive. Exiting..." -ForegroundColor Yellow
    exit
}

$portServices = @{
    80    = "HTTP";
    443   = "HTTPS";
    445   = "SMB";
    7070  = "WebLogic";
    7071  = "WebLogic";
    4786  = "Cisco Smart Install";
    4848  = "GlassFish";
    5555  = "HP Data Protector";
    5556  = "HP Data Protector";
    3300  = "SAP";
    6129  = "DameWare";
    6379  = "Redis";
    6970  = "Cisco Unified Comm Manager"
}

Write-Host "Scanning open ports on alive hosts..."

foreach ($aliveHost in $aliveHosts) {
    $ip = $aliveHost
    $firstThreeOctets = $ip -split '\.' | Select-Object -First 3
    $joined = $firstThreeOctets -join '.'
    $a = $ip -split '\.' | Select-Object -Last 1
    $combinedIP = "$joined.$a"
    Write-Host "Scanning ports for host $ip..."
    foreach ($port in $ports) {
        try {
            $tcpClient = New-Object Net.Sockets.TcpClient
            $asyncResult = $tcpClient.BeginConnect($combinedIP, $port, $null, $null)
            $waitHandle = $asyncResult.AsyncWaitHandle
            $result = $waitHandle.WaitOne(1000, $false)
            if ($result -and $tcpClient.Connected) {
                Write-Host "Port $port is open on $ip! Service: $($portServices[$port])" -ForegroundColor Green
                $tcpClient.EndConnect($asyncResult) | Out-Null
            } else {
                Write-Host "Port $port is closed on $ip." -ForegroundColor Red
            }
            $waitHandle.Dispose()
            $tcpClient.Close()
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 1000)
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Host $errorMessage -ForegroundColor Yellow
        }
        Start-Sleep -Milliseconds (Get-Random -Minimum 200 -Maximum 500)
    }
}
