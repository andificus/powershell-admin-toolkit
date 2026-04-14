<#
.SYNOPSIS
    Audits local Administrators group membership across multiple machines.

.DESCRIPTION
    Connects to one or more machines and reports who is in the local
    Administrators group on each. Useful for security audits and
    identifying unauthorized admin access.

.PARAMETER Computers
    Comma-separated list of computer names or IPs. Defaults to localhost.

.PARAMETER ExportPath
    Optional path to export results as a CSV file.

.EXAMPLE
    .\Audit-LocalAdminGroups.ps1
    .\Audit-LocalAdminGroups.ps1 -Computers "PC01","PC02","Server01"
    .\Audit-LocalAdminGroups.ps1 -Computers "PC01","PC02" -ExportPath "C:\Audits\admins.csv"

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
        $admins = Invoke-Command -ComputerName $computer -ScriptBlock {
            $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
            $group.Members() | ForEach-Object {
                $_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null)
            }
        } -ErrorAction Stop

        foreach ($admin in $admins) {
            $results += [PSCustomObject]@{
                Computer  = $computer
                Member    = $admin
                Status    = "✅ Retrieved"
            }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            Computer  = $computer
            Member    = "N/A"
            Status    = "❌ UNREACHABLE — $($_.Exception.Message)"
        }
    }
}

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