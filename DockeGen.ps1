# Copyright 2025 Harery (https://github.com/Harery, https://www.harery.com)
# Licensed under the Apache License, Version 2.0. See LICENSE file.

# DockGen.ps1
# Version: MVP 0.2 with Security Hardening
# Author: Mohamed ElHarery
# Purpose: Generate Dockerfile, docker-compose.yml, README.md for secure, customized developer containers

# Import modules
Import-Module "$PSScriptRoot\modules\UserInput.ps1"
Import-Module "$PSScriptRoot\modules\DockerfileGen.ps1"
Import-Module "$PSScriptRoot\modules\ComposeGen.ps1"
Import-Module "$PSScriptRoot\modules\ReadmeGen.ps1"

Clear-Host

Write-Host "=============================" -ForegroundColor Cyan
Write-Host "      DockGen CLI MVP        " -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Get user inputs
$userInputs = Get-UserInputs

# Check if files exist and prompt for overwrite
foreach ($file in @("Dockerfile", "docker-compose.yml", "README.md")) {
    if (Test-Path $file) {
        $overwrite = Read-Host "File '$file' already exists. Overwrite? (yes/no)"
        if ($overwrite -ne "yes") {
            Write-Host "Skipping generation of '$file'." -ForegroundColor Yellow
            continue
        }
    }

    # Generate content based on file type
    switch ($file) {
        "Dockerfile" {
            $content = Generate-Dockerfile -inputs $userInputs
        }
        "docker-compose.yml" {
            $content = Generate-ComposeFile -inputs $userInputs
        }
        "README.md" {
            $content = Generate-Readme -inputs $userInputs
        }
    }

    # Write content to file
    $content | Out-File -Encoding UTF8 -FilePath $file
    Write-Host "Generated '$file'." -ForegroundColor Green
}

Write-Host "\n✅ Dockerfile, docker-compose.yml, and README.md have been generated with security hardening options." -ForegroundColor Green
Write-Host "You can now build and run your secure developer container using Docker Compose." -ForegroundColor Green
