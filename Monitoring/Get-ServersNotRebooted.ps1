<#
.SYNOPSIS
    Finds servers that have not been rebooted within a specified number of days.

.DESCRIPTION
    Queries one or more servers for their last boot time and flags any that
    haven't rebooted within the defined threshold. Useful for patch compliance
    and uptime auditing.

.PARAMETER Servers
    Comma-separated list of server names or IPs. Defaults to localhost.

.PARAMETER DaysThreshold
    Number of days since last reboot before flagging a server. Default is 30.

.EXAMPLE
    .\Get-ServersNotRebooted.ps1
    .\Get-ServersNotRebooted.ps1 -Servers "Server01","Server02" -DaysThreshold 14

.NOTES
    Run as Administrator for remote server access.
#>

param (
    [string[]]$Servers = @("localhost"),
    [int]$DaysThreshold = 30
)

$results = @()

foreach ($server in $Servers) {
    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $server -ErrorAction Stop
        $lastBoot = $os.ConvertToDateTime($os.LastBootUpTime)
        $daysSinceBoot = (New-TimeSpan -Start $lastBoot -End (Get-Date)).Days
        $status = if ($daysSinceBoot -gt $DaysThreshold) { "⚠️ REBOOT NEEDED" } else { "✅ OK" }

        $results += [PSCustomObject]@{
            Server            = $server
            "Last Reboot"     = $lastBoot.ToString("yyyy-MM-dd HH:mm")
            "Days Up"         = $daysSinceBoot
            Status            = $status
        }
    }
    catch {
        $results += [PSCustomObject]@{
            Server            = $server
            "Last Reboot"     = "N/A"
            "Days Up"         = "N/A"
            Status            = "❌ UNREACHABLE"
        }
    }
}

$results | Format-Table -AutoSize

# Highlight servers needing reboot
$needsReboot = $results | Where-Object { $_.Status -like "*REBOOT*" }
if ($needsReboot) {
    Write-Host "`n⚠️  The following servers have not rebooted in over $DaysThreshold days:" -ForegroundColor Yellow
    $needsReboot | Format-Table -AutoSize
} else {
    Write-Host "`n✅ All servers have rebooted within the last $DaysThreshold days." -ForegroundColor Green
}