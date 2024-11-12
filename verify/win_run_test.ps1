#!/usr/bin/env powershell

# Small helper to avoid needing to write 'Check-Exit' after every
# non-powershell instruction.  It simply prints then executes the _QUOTED_
# argument followed by Check-Exit.
# N/B: Escape any nested quotes with back-tick ("`") characters.
# WARNING: DO NOT use this with powershell builtins! It will not do what you expect!
function Run-Command {
    param (
        [string] $command
    )

    Write-Host $command

    # The command output is saved into the variable $unformattedLog to be
    # processed by `logformatter` later. The alternative is to redirect the
    # command output to logformatter using a pipeline (`|`). But this approach
    # doesn't work as the command exit code would be overridden by logformatter.
    # It isn't possible to get a behavior of bash `pipefail` on Windows.
    Invoke-Expression $command -OutVariable unformattedLog | Write-Output

    $exitCode = $LASTEXITCODE

    if ($Env:CIRRUS_CI -eq "true") {
        Invoke-Logformatter $unformattedLog
    }

    Check-Exit 2 "'$command'" "$exitCode"
}

# Non-powershell commands do not halt execution on error!  This helper
# should be called after every critical operation to check and halt on a
# non-zero exit code.  Be careful not to use this for powershell commandlets
# (builtins)!  They set '$?' to "True" (failed) or "False" success so calling
# this would mask failures.  Rely on $ErrorActionPreference = 'Stop' instead.
function Check-Exit {
    param (
        [int] $stackPos = 1,
        [string] $command = 'command',
        [string] $exitCode = $LASTEXITCODE # WARNING: might not be a number!
    )

    if ( ($exitCode -ne $null) -and ($exitCode -ne 0) ) {
        # https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.callstackframe
        $caller = (Get-PSCallStack)[$stackPos]
        throw "Exit code = '$exitCode' running $command at $($caller.ScriptName):$($caller.ScriptLineNumber)"
    }
}


if ($args.Count -lt 1) {
    Write-Output "Must supply fully-qualified path to machine image"
    exit 1
}

# Set required environment variable for ginkgo and the test suite
$env:MACHINE_IMAGE_PATH=$args[0]

# Run the tests
Run-Command "ginkgo -v"
