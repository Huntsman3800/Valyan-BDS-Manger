# ==============================================
# Start-Bedrock.ps1
# Launch Bedrock server with auto-restart,
# daily backup at 4:00 AM, and cleanup
# ==============================================
$BDSPath      = "C:\BDS"
$ExePath      = Join-Path $BDSPath "bedrock_server.exe"
$WorldsPath   = Join-Path $BDSPath "worlds"
$WorldName    = "level"
$BackupPath   = Join-Path $BDSPath "backups"
$TempPath     = Join-Path $BDSPath "tempbackup"
$LogFile      = Join-Path $BDSPath "backup.log"
$RetentionDays = 14  # Delete backups older than 2 weeks

# Ensure directories exist
foreach ($dir in @($BackupPath, $TempPath)) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}

# Function to log messages
function Log($msg) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] $msg"
    Add-Content $LogFile $line
    Write-Host $line
}

# Function to clean up old backups
function CleanupOldBackups {
    try {
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $oldBackups = Get-ChildItem -Path $BackupPath -Filter "Backup_*.zip" | 
                      Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        if ($oldBackups.Count -gt 0) {
            Log "Cleaning up $($oldBackups.Count) old backup(s)..."
            foreach ($backup in $oldBackups) {
                Remove-Item $backup.FullName -Force
                Log "Deleted: $($backup.Name)"
            }
        }
    } catch {
        Log "Error during backup cleanup: $_"
    }
}

# Function to perform backup
function BackupWorld {
    try {
        Log "Backup started."
        
        # Freeze world
        Write-Host "Freezing world..."
        Log "Sending command: save hold"
        $script:proc.StandardInput.WriteLine("save hold")
        Start-Sleep -Seconds 3
        Log "Waited 3 seconds for world to freeze"
        
        # Copy world to temp folder
        $Source = Join-Path $WorldsPath $WorldName
        $Dest   = Join-Path $TempPath $WorldName
        if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
        Log "Copying world files to temp folder..."
        Copy-Item $Source $Dest -Recurse
        Log "Copy complete"
        
        # Resume world IMMEDIATELY after copy
        Write-Host "Resuming world..."
        Log "Sending command: save resume"
        $script:proc.StandardInput.WriteLine("save resume")
        Log "World resumed - players can continue playing"
        
        # Now zip the temp folder while server is running
        Log "Compressing backup (server is running)..."
        $Timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
        $ZipName = "Backup_$Timestamp.zip"
        $ZipFile = Join-Path $BackupPath $ZipName
        Compress-Archive -Path $Dest -DestinationPath $ZipFile
        Log "Compression complete"
        
        # Cleanup temp folder
        Remove-Item $Dest -Recurse -Force
        
        Log "Backup completed: $ZipFile"
        
        # Clean up old backups after successful backup
        CleanupOldBackups
        
    } catch {
        Log "Backup failed: $_"
        # Try to resume anyway
        if ($script:proc -and !$script:proc.HasExited) {
            Log "Attempting to resume world after error..."
            $script:proc.StandardInput.WriteLine("save resume")
            Log "Resume command sent"
        }
    }
}

# -----------------------------------------
# Keep-Alive Loop: Restart server if crashed
# -----------------------------------------
$keepRunning = $true
$script:lastBackupDay = -1  # Track last backup day in main script scope
Log "=== Server script started with keep-alive ==="
Log "Automatic backups will run daily at 4:00 AM"

while ($keepRunning) {
    
    # -----------------------------------------
    # Start server process
    # -----------------------------------------
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ExePath
    $psi.WorkingDirectory = $BDSPath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError  = $false
    $psi.CreateNoWindow = $false
    
    $script:proc = New-Object System.Diagnostics.Process
    $script:proc.StartInfo = $psi
    $script:proc.Start() | Out-Null
    
    Log "Bedrock server started. PID: $($script:proc.Id)"
    Write-Host "Server console ready. Type 'backup' for manual backup, 'stop' to shutdown gracefully."
    Write-Host "Automatic backups run daily at 4:00 AM (checks every 30 seconds)."
    Write-Host "==============================="
    
    # -----------------------------------------
    # Interactive console loop with polling
    # -----------------------------------------
    while ($script:proc.HasExited -eq $false) {
        
        # Check if it's time for automatic backup (4:00 AM)
        $now = Get-Date
        if ($now.Hour -eq 4 -and $now.Minute -lt 2 -and $now.Day -ne $script:lastBackupDay) {
            Log "Automatic backup triggered at 4:00 AM"
            $script:lastBackupDay = $now.Day
            BackupWorld
        }
        
        # Poll for user input with 30-second timeout
        $startTime = Get-Date
        $inputReceived = $false
        $cmd = ""
        
        while (((Get-Date) - $startTime).TotalSeconds -lt 30 -and !$inputReceived) {
            # FIRST: Check if server crashed (most important)
            # Use multiple methods to detect if process is dead
            $processAlive = $false
            try {
                # Refresh the process object
                $script:proc.Refresh()
                $processAlive = !$script:proc.HasExited
                
                # Double-check by looking up the process by ID
                if ($processAlive) {
                    $checkProc = Get-Process -Id $script:proc.Id -ErrorAction SilentlyContinue
                    $processAlive = ($null -ne $checkProc)
                }
            } catch {
                $processAlive = $false
            }
            
            if (!$processAlive) {
                Log "Server process detected as exited during input wait"
                break
            }
            
            # Recheck backup time during wait (in case we're waiting at 3:59 AM)
            $now = Get-Date
            if ($now.Hour -eq 4 -and $now.Minute -lt 2 -and $now.Day -ne $script:lastBackupDay) {
                Log "Automatic backup triggered at 4:00 AM (detected during wait)"
                $script:lastBackupDay = $now.Day
                BackupWorld
            }
            
            # Check if key is available (non-blocking check)
            if ([Console]::KeyAvailable) {
                $cmd = Read-Host
                $inputReceived = $true
                break
            }
            
            Start-Sleep -Milliseconds 250
        }
        
        # Log every hour to confirm script is alive
        if ((Get-Date).Minute -eq 0) {
            Log "Heartbeat: Script running, waiting for commands or 4 AM backup time"
        }
        
        # Process command if received
        if ($inputReceived) {
            if ($cmd -eq "backup") {
                BackupWorld
            } 
            elseif ($cmd -eq "stop") {
                Log "Graceful shutdown requested..."
                $script:proc.StandardInput.WriteLine("stop")
                Start-Sleep -Seconds 5
                $keepRunning = $false
                break
            }
            elseif ($cmd -like "exit*" -or $cmd -like "quit*") {
                Log "Exit requested - disabling keep-alive..."
                $keepRunning = $false
                $script:proc.StandardInput.WriteLine("stop")
                Start-Sleep -Seconds 5
                break
            }
            elseif ($cmd -eq "status") {
                Write-Host "Server running. Last backup day: $script:lastBackupDay, Current day: $((Get-Date).Day)"
                Log "Status check - Last backup day: $script:lastBackupDay, Current day: $((Get-Date).Day)"
            }
            else {
                # Forward other commands to server
                $script:proc.StandardInput.WriteLine($cmd)
            }
        }
    }
    
    # Check if server crashed or exited normally
    if ($script:proc.HasExited -and $keepRunning) {
        $exitCode = $script:proc.ExitCode
        Log "!!! Server process exited unexpectedly with code: $exitCode !!!"
        Log "Restarting in 10 seconds..."
        Start-Sleep -Seconds 10
    } else {
        Log "Server stopped normally."
    }
}

Log "=== Server script ended ==="
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")