<#
.SYNOPSIS
    Creates multiple Active Directory users from a CSV file.

.DESCRIPTION
    Reads a CSV file and creates AD user accounts based on the provided data.
    Handles password setting, OU placement, and group membership.
    Skips users that already exist and logs all actions.

.PARAMETER CSVPath
    Path to the CSV file containing user data.
    Required columns: FirstName, LastName, Username, Password, OU, Department, Title

.PARAMETER LogPath
    Path to write the log file. Defaults to .\BulkUserCreate.log

.EXAMPLE
    .\Bulk-CreateUsersFromCSV.ps1 -CSVPath ".\users.csv"
    .\Bulk-CreateUsersFromCSV.ps1 -CSVPath ".\users.csv" -LogPath "C:\Logs\userimport.log"

.NOTES
    Requires the Active Directory PowerShell module.
    Run as Administrator or with Domain Admin credentials.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$CSVPath,

    [string]$LogPath = ".\BulkUserCreate.log"
)

# --- Logging Function ---
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $entry
    switch ($Level) {
        "INFO"    { Write-Host $entry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $entry -ForegroundColor Green }
        "WARNING" { Write-Host $entry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $entry -ForegroundColor Red }
    }
}

# --- Check for AD Module ---
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Log "Active Directory module not found. Please install RSAT." "ERROR"
    exit 1
}
Import-Module ActiveDirectory

# --- Check CSV Exists ---
if (-not (Test-Path $CSVPath)) {
    Write-Log "CSV file not found at path: $CSVPath" "ERROR"
    exit 1
}

$users = Import-Csv -Path $CSVPath
Write-Log "Loaded $($users.Count) users from $CSVPath"

$created = 0
$skipped = 0
$failed  = 0

foreach ($user in $users) {
    $fullName = "$($user.FirstName) $($user.LastName)"

    try {
        # Check if user already exists
        if (Get-ADUser -Filter { SamAccountName -eq $user.Username } -ErrorAction SilentlyContinue) {
            Write-Log "User already exists, skipping: $($user.Username)" "WARNING"
            $skipped++
            continue
        }

        $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force

        New-ADUser `
            -GivenName        $user.FirstName `
            -Surname          $user.LastName `
            -Name             $fullName `
            -SamAccountName   $user.Username `
            -UserPrincipalName "$($user.Username)@$((Get-ADDomain).DNSRoot)" `
            -Path             $user.OU `
            -Department       $user.Department `
            -Title            $user.Title `
            -AccountPassword  $securePassword `
            -Enabled          $true `
            -ChangePasswordAtLogon $true

        Write-Log "Created user: $($user.Username) ($fullName)" "SUCCESS"
        $created++
    }
    catch {
        Write-Log "Failed to create user: $($user.Username) — $($_.Exception.Message)" "ERROR"
        $failed++
    }
}

# --- Summary ---
Write-Log "----------------------------------------"
Write-Log "Import complete. Created: $created | Skipped: $skipped | Failed: $failed"
Write-Log "Log saved to: $LogPath"