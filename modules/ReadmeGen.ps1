# Copyright 2025 Harery (https://github.com/Harery, https://www.harery.com)
# Licensed under the Apache License, Version 2.0. See LICENSE file.

function Generate-Readme {
    param($inputs)

    $readmeContent = @"
# DockGen Generated Container

## Base Image
$($inputs.baseImage)

## System Updates
$($inputs.updateCommands)

## User
Username: $($inputs.username)

## Usage

### Build
```
docker-compose build
```

### Run
```
docker-compose up -d
```

### Access
```
docker exec -it dockgen_container /bin/bash
```

Generated with **DockGen PowerShell CLI MVP**
"@

    return $readmeContent
}
