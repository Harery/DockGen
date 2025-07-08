# Copyright 2025 Harery (https://github.com/Harery, https://www.harery.com)
# Licensed under the Apache License, Version 2.0. See LICENSE file.

function Generate-Dockerfile {
    param($inputs)

    $installCommands = @()

    if ($inputs.installSSH) {
        $installCommands += "RUN apt-get update && apt-get install -y openssh-server"
    }

    $dockerfileContent = @"
FROM $($inputs.baseImage)

RUN $($inputs.updateCommands)

RUN useradd -m $($inputs.username) && echo '$($inputs.username):$($inputs.password)' | chpasswd
$($inputs.sudoBlock)

$($installCommands -join "`n")

# Use JSON format for CMD to prevent issues with OS signals
CMD ["/bin/bash"]
"@

    return $dockerfileContent
}
