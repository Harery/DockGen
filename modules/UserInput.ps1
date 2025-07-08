# Copyright 2025 Harery (https://github.com/Harery, https://www.harery.com)
# Licensed under the Apache License, Version 2.0. See LICENSE file.

function Get-UserInputs {
    # Collect base image
    $baseImage = Read-Host "Enter base image (default: ubuntu:24.04)"
    if ([string]::IsNullOrWhiteSpace($baseImage)) {
        $baseImage = "ubuntu:24.04"
    } elseif ($baseImage -notmatch "^[a-zA-Z0-9][a-zA-Z0-9_.-]*(?::[a-zA-Z0-9_.-]*){0,1}$") {
        Write-Host "Invalid base image format. Using default: ubuntu:24.04" -ForegroundColor Red
        $baseImage = "ubuntu:24.04"
    }

    # System update level
    Write-Host "Select system update level:" -ForegroundColor Yellow
    Write-Host "1) Basic (apt update)"
    Write-Host "2) Recommended (apt update + upgrade)"
    Write-Host "3) Full (apt update + upgrade + dist-upgrade)"
    $updateChoice = Read-Host "Enter choice (1/2/3)"
    while ($updateChoice -notin @("1", "2", "3")) {
        Write-Host "Invalid choice. Please select 1, 2, or 3." -ForegroundColor Red
        $updateChoice = Read-Host "Enter choice (1/2/3)"
    }
    switch ($updateChoice) {
        "1" { $updateCommands = "apt update" }
        "2" { $updateCommands = "apt update && apt upgrade -y" }
        "3" { $updateCommands = "apt update && apt upgrade -y && apt dist-upgrade -y && apt autoremove -y" }
        default { $updateCommands = "apt update" }
    }

    # Username and password
    $username = Read-Host "Enter username to create"
    while ([string]::IsNullOrWhiteSpace($username) -or $username -notmatch "^[a-zA-Z][a-zA-Z0-9_]*$") {
        Write-Host "Username must not be empty and must contain only letters, numbers, and underscores, starting with a letter." -ForegroundColor Red
        $username = Read-Host "Enter username to create"
    }

    $password = Read-Host "Enter password for user $username"
    while ([string]::IsNullOrWhiteSpace($password) -or $password.Length -lt 8) {
        Write-Host "Password must not be empty and must be at least 8 characters long." -ForegroundColor Red
        $password = Read-Host "Enter password for user $username"
    }

    # User privileges
    Write-Host "Select user privileges:" -ForegroundColor Yellow
    Write-Host "1) Regular user"
    Write-Host "2) Sudo access"
    Write-Host "3) Passwordless sudo"
    $userPrivChoice = Read-Host "Enter choice (1/2/3)"
    while ($userPrivChoice -notin @("1", "2", "3")) {
        Write-Host "Invalid choice. Please select 1, 2, or 3." -ForegroundColor Red
        $userPrivChoice = Read-Host "Enter choice (1/2/3)"
    }
    switch ($userPrivChoice) {
        "1" { $sudoBlock = "" }
        "2" { $sudoBlock = "RUN usermod -aG sudo $username" }
        "3" { $sudoBlock = "RUN usermod -aG sudo $username`nRUN echo '$username ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers" }
        default { $sudoBlock = "" }
    }

    # Prompt for additional installations
    # Prompt for SSH server installation
    $installSSH = Read-Host "Do you want to install SSH Server? (yes/no)"
    while ($installSSH -notin @("yes", "no")) {
        Write-Host "Invalid choice. Please enter 'yes' or 'no'." -ForegroundColor Red
        $installSSH = Read-Host "Do you want to install SSH Server? (yes/no)"
    }
    if ($installSSH -eq "yes") {
        $sshCommand = "apt install -y openssh-server"
    } else {
        $sshCommand = ""
    }

    $installCommands = "$sshCommand"
    $installSSHFlag = $installSSH -eq "yes"

    return @{ baseImage = $baseImage; updateCommands = $updateCommands; username = $username; password = $password; sudoBlock = $sudoBlock; installCommands = $installCommands; installSSH = $installSSHFlag }
}
