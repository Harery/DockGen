# Copyright 2025 Harery (https://github.com/Harery, https://www.harery.com)
# Licensed under the Apache License, Version 2.0. See LICENSE file.

# PostOps.ps1
# Automates post-start operations for DockGen container

function Generate-DockGenContainerName {
    param($distroName)

    $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    return "DockGen-$distroName-$timestamp"
}

function Check-ContainerHealth {
    param($containerName)

    # Check if the container is running
    $containerStatus = docker inspect -f '{{.State.Status}}' $containerName

    if ($containerStatus -eq "running") {
        Write-Host "\n===============================" -ForegroundColor Cyan
        Write-Host "🚀  Container $containerName is RUNNING" -ForegroundColor Green
        Write-Host "===============================\n" -ForegroundColor Cyan

        # Health check
        try {
            $healthCheckResult = docker exec $containerName bash -c "echo Health Check Passed"
            Write-Host "✅  Health Check: $healthCheckResult" -ForegroundColor Green
        } catch {
            Write-Host "❌  Health Check Failed." -ForegroundColor Red
        }

        # Get container IPv4 address
        $ipv4Address = docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $containerName
        Write-Host "🌐  Container IPv4 Address: $ipv4Address" -ForegroundColor Cyan

        # Check if apt commands are executed
        $aptCommands = @(
            "apt update",
            "apt upgrade -y",
            "apt dist-upgrade -y",
            "apt autoremove -y"
        )

        foreach ($command in $aptCommands) {
            try {
                $safeCommand = "DEBIAN_FRONTEND=noninteractive apt-get -o=Dpkg::Use-Pty=0 -o=APT::Color=0 -qq ${command} 2> /dev/null"
                $commandResult = docker exec $containerName bash -c "$safeCommand"
                Write-Host "✔️  '$command' executed successfully." -ForegroundColor Green
            } catch {
                Write-Host "❌  '$command' failed." -ForegroundColor Red
            }
        }

        # Dynamically detect all users with UID >= 1000 (created users, not system users)
        try {
            $userList = docker exec $containerName bash -c 'while IFS=: read -r user x uid gid desc homeDir shell; do if [ "$uid" -ge 1000 ] && [ "$user" != "nobody" ]; then printf "%s||%s||%s||%s||%s||%s##" "$user" "$uid" "$gid" "$desc" "$homeDir" "$shell"; fi; done < /etc/passwd'
            if ($userList) {
                $userListFlat = $userList -replace "\r?\n", ""
                $userEntries = $userListFlat -split '##'
                Write-Host "\nUser            UID     GID     Description          Home                 Shell" -ForegroundColor White
                Write-Host "----            ---     ---     -----------          ----                 -----" -ForegroundColor White
                foreach ($userEntry in $userEntries) {
                    $userEntry = $userEntry.Trim()
                    if ($userEntry -and $userEntry -ne "") {
                        $parts = $userEntry.Split("||")
                        if ($parts.Count -ge 6) {
                            $user = $parts[0]
                            $uid = $parts[1]
                            $gid = $parts[2]
                            $desc = $parts[3]
                            $homeDir = $parts[4]
                            $shell = $parts[5]
                            Write-Host ("{0,-15} {1,-7} {2,-7} {3,-20} {4,-20} {5,-15}" -f $user, $uid, $gid, $desc, $homeDir, $shell) -ForegroundColor Yellow
                        } else {
                            Write-Host ("[DEBUG] Malformed user entry: {0}" -f $userEntry) -ForegroundColor Magenta
                        }
                    }
                }
            } else {
                Write-Host "No created users (UID >= 1000) found in the container." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "❌  Failed to retrieve user info." -ForegroundColor Red
        }

        # Check SSH server status and port 22 availability
        try {
            $sshStatus = docker exec $containerName bash -c "service ssh status || service sshd status"
            if ($sshStatus -match "running") {
                Write-Host "🟢  SSH server is running." -ForegroundColor Green
            } else {
                Write-Host "🔴  SSH server is NOT running." -ForegroundColor Red
            }

            $port22Status = docker exec $containerName bash -c "netstat -tuln | grep ':22 '"
            if ($port22Status) {
                Write-Host "🟢  Port 22 is open and listening." -ForegroundColor Green
            } else {
                Write-Host "🔴  Port 22 is NOT open." -ForegroundColor Red
            }
        } catch {
            Write-Host "❌  Failed to check SSH server or port 22 status." -ForegroundColor Red
        }

        # Check if root login via SSH is disabled
        try {
            $rootLoginStatus = docker exec $containerName bash -c "grep '^PermitRootLogin' /etc/ssh/sshd_config"
            if ($rootLoginStatus -match "no") {
                Write-Host "🟢  Root login via SSH is DISABLED." -ForegroundColor Green
            } else {
                Write-Host "🔴  Root login via SSH is ENABLED." -ForegroundColor Red
            }
        } catch {
            Write-Host "❌  Failed to check root login SSH configuration." -ForegroundColor Red
        }

        try {
            $sshInstall = docker exec $containerName bash -c "DEBIAN_FRONTEND=noninteractive apt-get -o=Dpkg::Use-Pty=0 -o=APT::Color=0 -qq install -y openssh-server net-tools 2> /dev/null"
            Write-Host "🟢  'openssh-server' and 'net-tools' installed." -ForegroundColor Green
        } catch {
            Write-Host "❌  Failed to install 'openssh-server' or 'net-tools'." -ForegroundColor Red
        }

        try {
            $disableRootLogin = docker exec $containerName bash -c "sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config"
            Write-Host "🟢  Root login via SSH disabled in sshd_config." -ForegroundColor Green
        } catch {
            Write-Host "❌  Failed to disable root login via SSH." -ForegroundColor Red
        }

        try {
            $startSSH = docker exec $containerName bash -c "service ssh start || service sshd start"
            Write-Host "🟢  SSH server started." -ForegroundColor Green
        } catch {
            Write-Host "❌  Failed to start SSH server." -ForegroundColor Red
        }

        Write-Host "\n===============================" -ForegroundColor Cyan
        Write-Host "✅  Post-ops checks complete for $containerName" -ForegroundColor Green
        Write-Host "===============================\n" -ForegroundColor Cyan
    } else {
        Write-Host "\n===============================" -ForegroundColor Red
        Write-Host "❌  Container $containerName is NOT running." -ForegroundColor Red
        Write-Host "===============================\n" -ForegroundColor Red
    }
}

# Example usage:
# $distroName = "ubuntu"
# $containerName = Generate-DockGenContainerName -distroName $distroName
# Write-Host "Generated container name: $containerName" -ForegroundColor Green

# Use the actual running container name
$containerName = "dockgen_container"
Check-ContainerHealth -containerName $containerName

