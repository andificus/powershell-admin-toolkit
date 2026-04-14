<#
.SYNOPSIS
    Checks disk space on local or remote servers and flags drives below a threshold.

.DESCRIPTION
    Queries one or more servers for disk space usage on all fixed drives.
    Flags any drive below the warning threshold (default: 20% free).

.PARAMETER Servers
    Comma-separated list of server names or IPs. Defaults to localhost.

.PARAMETER ThresholdPercent
    Percentage of free space that triggers a warning. Default is 20.

.EXAMPLE
    .\Check-DiskSpace.ps1
    .\Check-DiskSpace.ps1 -Servers "Server01","Server02" -ThresholdPercent 15

.NOTES
    Run as Administrator for remote server access.
#>

param (
    [string[]]$Servers = @("localhost"),
    [int]$ThresholdPercent = 20
)

$results = @()

foreach ($server in $Servers) {
    try {
        $disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $server -Filter "DriveType=3" -ErrorAction Stop

        foreach ($disk in $disks) {
            $freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $totalGB = [math]::Round($disk.Size / 1GB, 2)
            $status = if ($freePercent -lt $ThresholdPercent) { "⚠️ WARNING" } else { "✅ OK" }

            $results += [PSCustomObject]@{
                Server        = $server
                Drive         = $disk.DeviceID
                "Total (GB)"  = $totalGB
                "Free (GB)"   = $freeGB
                "Free %"      = "$freePercent%"
                Status        = $status
            }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            Server        = $server
            Drive         = "N/A"
            "Total (GB)"  = "N/A"
            "Free (GB)"   = "N/A"
            "Free %"      = "N/A"
            Status        = "❌ UNREACHABLE"
        }
    }
}

$results | Format-Table -AutoSize

# Highlight warnings
$warnings = $results | Where-Object { $_.Status -like "*WARNING*" }
if ($warnings) {
    Write-Host "`n⚠️  Low disk space detected on the following drives:" -ForegroundColor Yellow
    $warnings | Format-Table -AutoSize
} else {
    Write-Host "`n✅ All drives are within acceptable thresholds." -ForegroundColor Green
}