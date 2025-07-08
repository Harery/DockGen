# Copyright 2025 Harery (https://github.com/Harery, https://www.harery.com)
# Licensed under the Apache License, Version 2.0. See LICENSE file.

function Generate-ComposeFile {
    param($inputs)

    $composeContent = @"
version: '3.8'
services:
  dockgen:
    build: .
    container_name: dockgen_container
    ports:
      - '22:22'
    tty: true
"@

    return $composeContent
}
