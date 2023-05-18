[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Specify the path to the IP file. If not provided, it will look for ips.txt in the local folder.")]
    [string]$ipFile = "ips.txt",

    [Parameter(Mandatory=$false, HelpMessage="Specify custom ports to scan.")]
    [int[]]$customPorts,

    [switch]$help
)

function Show-Help {
    $helpText = @"
NAME
    ShadowScan.ps1

SYNOPSIS
    Scans open ports on specified IP addresses.

SYNTAX
    ./ShadowScan.ps1 [-ipFile <string>] [-customPorts <int[]>]

DESCRIPTION
    This script pings the specified IP addresses to check if they are alive and then scans for open ports on the alive hosts.

PARAMETERS
    -ipFile <string>
        Specify the path to the IP file. If not provided, it will look for ips.txt in the local folder.

    -customPorts <int[]>
        Specify custom ports to scan. If not provided, it will use the default port list.

EXAMPLES
    ./ShadowScan.ps1
    ./ShadowScan.ps1 -ipFile "C:\path\to\ip.txt"
    ./ShadowScan.ps1 -customPorts 80,443,3389
"@

    Write-Host $helpText
}

if ($help) {
    Show-Help
    exit
}

if ($ipFile -and (-not (Test-Path $ipFile -PathType Leaf))) {
    $ipFile = Join-Path $PSScriptRoot $ipFile
}

$ipAddresses = Get-Content $ipFile

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

$defaultPorts = @(80, 443, 445, 7070, 7071, 4786, 4848, 5555, 5556, 3300, 6129, 6379, 6970)
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
    $portsToScan = $defaultPorts
    if ($customPorts) {
        $portsToScan = $customPorts
    }
    foreach ($port in $portsToScan) {
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
