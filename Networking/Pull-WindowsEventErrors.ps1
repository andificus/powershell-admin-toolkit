<#
.SYNOPSIS
    Pulls and summarizes error events from Windows Event Logs.

.DESCRIPTION
    Queries the System and Application event logs on local or remote machines
    for error-level events within a specified time window. Summarizes results
    by event source and optionally exports to CSV.

.PARAMETER Computers
    Comma-separated list of computer names or IPs. Defaults to localhost.

.PARAMETER HoursBack
    How many hours back to search for errors. Default is 24.

.PARAMETER ExportPath
    Optional path to export results as a CSV file.

.EXAMPLE
    .\Pull-WindowsEventErrors.ps1
    .\Pull-WindowsEventErrors.ps1 -Computers "Server01","Server02" -HoursBack 48
    .\Pull-WindowsEventErrors.ps1 -HoursBack 12 -ExportPath "C:\Logs\errors.csv"

.NOTES
    Run as Administrator for remote machine access.
    WinRM must be enabled on remote machines.
#>

param (
    [string[]]$Computers = @("localhost"),
    [int]$HoursBack = 24,
    [string]$ExportPath = ""
)

$results = @()
$startTime = (Get-Date).AddHours(-$HoursBack)

foreach ($computer in $Computers) {
    Write-Host "`nQuerying $computer for errors in the last $HoursBack hours..." -ForegroundColor Cyan

    foreach ($log in @("System", "Application")) {
        try {
            $events = Get-WinEvent -ComputerName $computer -FilterHashtable @{
                LogName   = $log
                Level     = 2  # Error
                StartTime = $startTime
            } -ErrorAction Stop

            foreach ($logEvent in $events) {
                $results += [PSCustomObject]@{
                    Computer    = $computer
                    Log         = $log
                    TimeCreated = $logEvent.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                    EventID     = $logEvent.Id
                    Source      = $logEvent.ProviderName
                    Message     = $logEvent.Message.Split("`n")[0].Trim()
                }
            }

            Write-Host "  [$log] Found $($events.Count) error(s)" -ForegroundColor $(if ($events.Count -gt 0) { "Yellow" } else { "Green" })
        }
        catch [System.Exception] {
            if ($_.Exception.Message -like "*No events*") {
                Write-Host "  [$log] No errors found" -ForegroundColor Green
            } else {
                Write-Host "  [$log] ❌ Failed to query — $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

if ($results.Count -gt 0) {
    Write-Host "`n--- Error Summary ---" -ForegroundColor Cyan
    $results | Group-Object Source | Sort-Object Count -Descending | Select-Object Count, Name | Format-Table -AutoSize

    Write-Host "`n--- Full Error List ---" -ForegroundColor Cyan
    $results | Format-Table -AutoSize

    # Export if path provided
    if ($ExportPath -ne "") {
        try {
            $results | Export-Csv -Path $ExportPath -NoTypeInformation
            Write-Host "`n✅ Results exported to: $ExportPath" -ForegroundColor Green
        }
        catch {
            Write-Host "`n❌ Failed to export: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`n✅ No errors found across all queried machines and logs." -ForegroundColor Green
}