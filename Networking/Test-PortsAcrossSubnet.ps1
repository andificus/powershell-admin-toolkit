<#
.SYNOPSIS
    Tests common ports across a range of IP addresses.

.DESCRIPTION
    Scans a subnet or list of IPs and tests whether specified ports are
    open or closed. Useful for firewall audits, network troubleshooting,
    and inventory checks.

.PARAMETER Subnet
    The first three octets of the subnet to scan. Example: "192.168.1"

.PARAMETER StartHost
    The starting host number. Default is 1.

.PARAMETER EndHost
    The ending host number. Default is 254.

.PARAMETER Ports
    List of ports to test. Defaults to common ports: 80, 443, 3389, 445, 22

.PARAMETER TimeoutMS
    Timeout in milliseconds for each connection attempt. Default is 500.

.EXAMPLE
    .\Test-PortsAcrossSubnet.ps1 -Subnet "192.168.1"
    .\Test-PortsAcrossSubnet.ps1 -Subnet "10.0.0" -StartHost 1 -EndHost 50 -Ports 80,443,3389

.NOTES
    Run as Administrator for best results.
    Large subnets may take several minutes to complete.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Subnet,

    [int]$StartHost = 1,
    [int]$EndHost = 254,
    [int[]]$Ports = @(80, 443, 3389, 445, 22),
    [int]$TimeoutMS = 500
)

$results = @()

Write-Host "`nScanning $Subnet.$StartHost - $Subnet.$EndHost on ports: $($Ports -join ', ')" -ForegroundColor Cyan
Write-Host "This may take a moment...`n" -ForegroundColor Cyan

for ($i = $StartHost; $i -le $EndHost; $i++) {
    $ip = "$Subnet.$i"

    # Quick ping check first to skip dead hosts
    $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue

    if ($ping) {
        foreach ($port in $Ports) {
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $connect = $tcp.BeginConnect($ip, $port, $null, $null)
                $wait = $connect.AsyncWaitHandle.WaitOne($TimeoutMS, $false)

                if ($wait -and !$tcp.Client.Connected) {
                    $status = "❌ Closed"
                } elseif ($wait) {
                    $status = "✅ Open"
                } else {
                    $status = "⏱️ Timeout"
                }
                $tcp.Close()
            }
            catch {
                $status = "❌ Closed"
            }

            $results += [PSCustomObject]@{
                IP     = $ip
                Port   = $port
                Status = $status
            }
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No responsive hosts found in range." -ForegroundColor Yellow
} else {
    $results | Format-Table -AutoSize

    $openPorts = $results | Where-Object { $_.Status -like "*Open*" }
    Write-Host "`n✅ Found $($openPorts.Count) open port(s) across $($results.IP | Select-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count) host(s)." -ForegroundColor Green
}