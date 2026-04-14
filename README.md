# PowerShell Admin Toolkit

A collection of PowerShell scripts for common IT administration, monitoring, and automation tasks.

Built for sysadmins and IT engineers who want to automate the repetitive stuff.

---

## 📁 Structure

| Folder | Purpose |
|---|---|
| `ActiveDirectory/` | User management, auditing, OU tasks |
| `Monitoring/` | Disk space, uptime, server health checks |
| `Networking/` | Port testing, subnet scanning |
| `Logs/` | Windows Event Log parsing and reporting |
| `Utilities/` | General-purpose IT utility scripts |

---

## ⚙️ Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Active Directory module (for AD scripts)
- Run as Administrator where noted

---

## 🚀 Usage

Each script is self-contained. Clone the repo, navigate to the script you need, and run it directly or dot-source it into your session.

```powershell
.\ActiveDirectory\Bulk-CreateUsersFromCSV.ps1
```

---

## 📌 Scripts

### Active Directory
- **Bulk-CreateUsersFromCSV** — Create multiple AD users from a CSV file
- **Audit-LocalAdminGroups** — Report local admin group membership across machines

### Monitoring
- **Check-DiskSpace** — Check disk space on local or remote servers and flag low space
- **Get-ServersNotRebooted** — Find servers that haven't rebooted in X days

### Networking
- **Test-PortsAcrossSubnet** — Test common ports across a range of IPs

### Logs
- **Pull-WindowsEventErrors** — Pull and summarize errors from Windows Event Logs

---

## 🤝 Contributing

Feel free to fork and submit PRs. Scripts should be well-commented and include a usage example at the top.