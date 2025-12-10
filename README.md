# Valyan BDS Manager

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)

**Valyan BDS Manager** is a powerful, lightweight automation tool for managing Minecraft Bedrock Dedicated Servers on Windows. Featuring automatic crash recovery, intelligent backup scheduling, and streamlined server administration—all through a simple PowerShell script. Designed for reliability and performance, Valyan BDS Manager puts full control of your Minecraft Bedrock servers in your hands.

---

## ✨ Features

- **🔄 Automatic Crash Recovery** - Server automatically restarts if it crashes or stops unexpectedly
- **💾 Scheduled Daily Backups** - Automated world backups at 4:00 AM with minimal player disruption (only 3-second freeze)
- **🗑️ Smart Backup Cleanup** - Automatically removes backups older than 14 days to prevent disk overflow
- **📝 Comprehensive Logging** - Timestamped logs of all operations for easy troubleshooting
- **⌨️ Interactive Console** - Send commands to your server while the script runs
- **⚡ Optimized Backup Process** - Compression happens in the background while players continue playing
- **🔧 Easy Configuration** - Simple variables to customize paths, backup times, and retention periods

---

## 📋 Requirements

- **Windows 10/11** or **Windows Server 2016+**
- **PowerShell 5.1** or later (pre-installed on modern Windows)
- **Minecraft Bedrock Dedicated Server** installed
- Sufficient disk space for backups (compressed world files)

---

## ⚠️ Security Warning

**IMPORTANT: Read before installing!**

This tool is currently distributed as a PowerShell script (`.ps1` file). PowerShell scripts have full access to your system with your user permissions. Before running:

1. **Read through the entire script** to understand what it does
2. **Only download from trusted sources** (official GitHub repository)
3. **Verify the file hasn't been modified** after download
4. **Never run scripts from unknown sources** without reviewing them first

We are actively working on safer distribution methods (compiled executable, Docker container) for future releases. See [Roadmap](#-roadmap) below.

---

## 🚀 Quick Start

### 1. Download the Script

Download `Start-Bedrock.ps1` from the [latest release](https://github.com/Huntsman3800/Valyan-BDS-Manger/releases) or clone this repository:
```bash
git clone https://github.com/yourusername/valyan-bds-manager.git
```

### 2. Enable PowerShell Scripts (One-Time Setup)

Open PowerShell as Administrator and run:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Press `Y` when prompted. This allows you to run locally-created PowerShell scripts.

> **Alternative:** If you prefer not to change your execution policy, you can run the script with:
> ```powershell
> powershell.exe -ExecutionPolicy Bypass -File "C:\BDS\Start-Bedrock.ps1"
> ```

### 3. Configure the Script

Edit `Start-Bedrock.ps1` and update these variables at the top:
```powershell
$BDSPath      = "C:\BDS"           # Path to your Bedrock server folder
$WorldName    = "level"            # Your world name (usually "level")
$RetentionDays = 14                # Days to keep old backups
```

### 4. Run the Script

Navigate to your BDS folder and run:
```powershell
cd C:\BDS
.\Start-Bedrock.ps1
```

Or simply right-click `Start-Bedrock.ps1` and select **"Run with PowerShell"**.

---

## 📖 Usage

### Interactive Commands

While the script is running, you can type these commands:

| Command | Description |
|---------|-------------|
| `backup` | Trigger an immediate manual backup |
| `stop` | Gracefully shutdown the server and exit the script |
| `exit` / `quit` | Same as `stop` |
| `status` | Check when the last backup ran |
| Any other command | Forwarded directly to the Bedrock server console |

### Server Commands Examples
```
list                    # Show online players
say Hello everyone!     # Broadcast a message
whitelist add PlayerName  # Add player to whitelist
stop                    # Stop the server gracefully
```

---

## ⚙️ Configuration

### Backup Schedule

By default, backups run daily at **4:00 AM**. To change this:

1. Find this line in the script:
```powershell
   if ($now.Hour -eq 4 -and $now.Minute -lt 2 -and $now.Day -ne $script:lastBackupDay)
```

2. Change `4` to your preferred hour (24-hour format):
```powershell
   if ($now.Hour -eq 2 -and $now.Minute -lt 2 -and $now.Day -ne $script:lastBackupDay)
```
   *(This example sets backups to 2:00 AM)*

### Backup Retention

Change how long backups are kept by modifying:
```powershell
$RetentionDays = 14  # Keep backups for 14 days
```

### Custom World Name

If your world isn't named "level":
```powershell
$WorldName = "MyCustomWorld"
```

---

## 🔧 Running as a Windows Service

To run Valyan BDS Manager as a background service (survives logouts, starts on boot):

### Using NSSM (Recommended)

1. Download [NSSM (Non-Sucking Service Manager)](https://nssm.cc/download)
2. Extract and run:
```cmd
   nssm install ValyanBDSManager
```
3. Configure the service:
   - **Path:** `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
   - **Startup directory:** `C:\BDS`
   - **Arguments:** `-ExecutionPolicy Bypass -File "C:\BDS\Start-Bedrock.ps1"`
4. Click **"Install Service"**
5. Start the service:
```cmd
   nssm start ValyanBDSManager
```

### Service Management Commands
```cmd
nssm start ValyanBDSManager    # Start the service
nssm stop ValyanBDSManager     # Stop the service
nssm restart ValyanBDSManager  # Restart the service
nssm remove ValyanBDSManager   # Uninstall the service
```

---

## 📂 File Structure
```
C:\BDS\
├── bedrock_server.exe       # Bedrock server executable
├── Start-Bedrock.ps1        # Valyan BDS Manager script
├── worlds\                  # World data
│   └── level\               # Default world
├── backups\                 # Compressed backup files
│   ├── Backup_2024-12-10_04-00-00.zip
│   └── Backup_2024-12-11_04-00-00.zip
├── tempbackup\              # Temporary folder during backup (auto-deleted)
└── backup.log               # Operation log file
```

---

## 🐛 Troubleshooting

### Script Won't Run - "Execution Policy" Error

**Error:** `cannot be loaded because running scripts is disabled`

**Solution:** Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Server Doesn't Restart After Crash

1. Check `backup.log` for error messages
2. Verify `bedrock_server.exe` path is correct in the script
3. Ensure you have proper file permissions in the BDS folder

### Backups Not Running at Scheduled Time

1. Verify the script is running continuously (not closed)
2. Check `backup.log` for backup entries
3. Use the `status` command to see the last backup day
4. Ensure your computer is on at the scheduled backup time

### Large Backup Files Filling Disk

1. Reduce `$RetentionDays` to keep fewer backups
2. Manually delete old backups from the `backups\` folder
3. Consider moving backups to external storage

### How to Restore a Backup

1. Stop the server: Type `stop` in the console
2. Navigate to `C:\BDS\backups\`
3. Extract the desired `Backup_YYYY-MM-DD_HH-mm-ss.zip`
4. Replace `C:\BDS\worlds\level\` with the extracted world folder
5. Restart the server

---

## 📊 How It Works

### The Backup Process

1. **Freeze World (3 seconds)** - `save hold` command prevents new writes
2. **Copy Files** - World folder copied to temporary location
3. **Resume Immediately** - `save resume` unfreezes the world (players can continue)
4. **Compress in Background** - ZIP compression happens while server runs
5. **Cleanup** - Temporary files deleted, old backups removed

**Result:** Players experience only a 3-second pause, not the full 30+ seconds compression takes.

### The Keep-Alive System

The script continuously monitors the server process. If it detects a crash:
1. Logs the exit code
2. Waits 10 seconds
3. Automatically restarts the server
4. Continues monitoring

This ensures maximum uptime even if the server crashes unexpectedly.

---

## 🗺️ Roadmap

We're committed to improving Valyan BDS Manager's security and usability:

### Planned Improvements

- [ ] **v2.0** - Compiled executable with digital signature
- [ ] Multi-world backup support
- [ ] Discord/webhook notifications
- [ ] Web-based control panel
- [ ] Docker container version
- [ ] Backup verification system
- [ ] Configurable backup schedules (multiple times per day)
- [ ] Cloud backup integration (Google Drive, Dropbox, AWS S3)
- [ ] Performance monitoring (TPS tracking)
- [ ] Cross-platform support (Linux/macOS)

### Current Limitations

- Windows-only (PowerShell script)
- Fixed backup time (requires editing script)
- Single world backup
- Local storage only
- No built-in verification of backup integrity

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch:** `git checkout -b feature/YourFeature`
3. **Commit your changes:** `git commit -m 'Add YourFeature'`
4. **Push to the branch:** `git push origin feature/YourFeature`
5. **Open a Pull Request**

### Areas We Need Help With

- Testing on different Windows versions
- Security auditing
- Documentation improvements
- Feature suggestions
- Bug reports

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚡ Support

- **Issues:** [GitHub Issues](https://github.com/Huntsman3800/valyan-bds-manager/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Huntsman3800/valyan-bds-manager/discussions)
- **Reddit:** r/admincraft

---

## 🙏 Acknowledgments

- The Minecraft Bedrock community for feedback and testing
- r/admincraft for support and suggestions
- All contributors who have helped improve this tool

---

## ⚠️ Disclaimer

Valyan BDS Manager is an unofficial tool and is not affiliated with, endorsed by, or connected to Mojang Studios or Microsoft. Minecraft is a trademark of Mojang Studios.

Use this tool at your own risk. Always maintain separate backups of your worlds. The developers are not responsible for any data loss or server issues.

---

**Made with ❤️ for the Minecraft Bedrock community**

---

## 🔗 Quick Links

- [Installation Guide](#-quick-start)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Security Warning](#-security-warning)
- [Changelog](CHANGELOG.md)
- [FAQ](FAQ.md)
