<#
.SYNOPSIS
    Collects system inventory information from local or remote machines.

.DESCRIPTION
    Queries one or more machines and returns a summary of hardware and OS
    information including hostname, OS version, CPU, RAM, and disk space.
    Useful for audits, asset tracking, and environment documentation.

.PARAMETER Computers
    Comma-separated list of computer names or IPs. Defaults to localhost.

.PARAMETER ExportPath
    Optional path to export results as a CSV file.

.EXAMPLE
    .\Get-SystemInventory.ps1
    .\Get-SystemInventory.ps1 -Computers "Server01","Server02"
    .\Get-SystemInventory.ps1 -Computers "Server01" -ExportPath "C:\Audits\inventory.csv"

.NOTES
    Run as Administrator for remote machine access.
    WinRM must be enabled on remote machines.
#>

param (
    [string[]]$Computers = @("localhost"),
    [string]$ExportPath = ""
)

$results = @()

foreach ($computer in $Computers) {
    try {
        $os   = Get-WmiObject -Class Win32_OperatingSystem  -ComputerName $computer -ErrorAction Stop
        $cpu  = Get-WmiObject -Class Win32_Processor        -ComputerName $computer -ErrorAction Stop
        $ram  = Get-WmiObject -Class Win32_PhysicalMemory   -ComputerName $computer -ErrorAction Stop
        $disk = Get-WmiObject -Class Win32_LogicalDisk      -ComputerName $computer -Filter "DriveType=3" -ErrorAction Stop

        $totalRAM  = [math]::Round(($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
        $totalDisk = [math]::Round(($disk | Measure-Object -Property Size -Sum).Sum / 1GB, 2)
        $freeDisk  = [math]::Round(($disk | Measure-Object -Property FreeSpace -Sum).Sum / 1GB, 2)

        $results += [PSCustomObject]@{
            Computer       = $computer
            Hostname       = $os.CSName
            OS             = $os.Caption
            "OS Version"   = $os.Version
            CPU            = $cpu[0].Name.Trim()
            "RAM (GB)"     = $totalRAM
            "Total Disk (GB)" = $totalDisk
            "Free Disk (GB)"  = $freeDisk
            "Last Reboot"  = $os.ConvertToDateTime($os.LastBootUpTime).ToString("yyyy-MM-dd HH:mm")
            Status         = "✅ Online"
        }
    }
    catch {
        $results += [PSCustomObject]@{
            Computer       = $computer
            Hostname       = "N/A"
            OS             = "N/A"
            "OS Version"   = "N/A"
            CPU            = "N/A"
            "RAM (GB)"     = "N/A"
            "Total Disk (GB)" = "N/A"
            "Free Disk (GB)"  = "N/A"
            "Last Reboot"  = "N/A"
            Status         = "❌ UNREACHABLE"
        }
    }
}

$results | Format-Table -AutoSize

# Export if path provided
if ($ExportPath -ne "") {
    try {
        $results | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✅ Inventory exported to: $ExportPath" -ForegroundColor Green
    }
    catch {
        Write-Host "`n❌ Failed to export: $($_.Exception.Message)" -ForegroundColor Red
    }
}