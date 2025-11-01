param (
    [switch]$WhatIf,
    [switch]$Confirm
)

function Main {
    $config = Read-Config

    $appName = $config.applicationName
    $pathToNirCmd = $config.pathToNirCmd

    Log "Looking for advertisements..."
    $wasAdPlaying = $false
    while ($true) {
        if (Assert-Ad-Playing $appName) {
            if ($wasAdPlaying) {
                continue
            }
            Log "Advertisement detected"
            Set-App-Volume `
                -appName $appName `
                -volume 0 `
                -pathToNirCmd $pathToNirCmd `
                -WhatIf:$WhatIf `
                -Confirm:$Confirm

            $wasAdPlaying = $true
            continue
        }

        if (-not $wasAdPlaying) {
            continue
        }

        Set-App-Volume `
            -appName $appName `
            -volume 1 `
            -pathToNirCmd $pathToNirCmd `
            -WhatIf:$WhatIf `
            -Confirm:$Confirm

        Start-Sleep -Milliseconds 500
    }
}

function Read-Config {
    Log "Reading config"
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
    return Get-Content $configFile -Raw | ConvertFrom-Json
}

function Assert-Ad-Playing {
    param (
        [string]$appName
    )
    Get-Process $appName -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($_.MainWindowTitle -like "*Advertisement*") {
                return $true
            }
        }

    return $false
}

function Set-App-Volume {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
    param (
        [string]$appName,
        [float]$volume,
        [string]$pathToNirCmd
    )

    $executable = Get-Process $appName -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty Path |
        ForEach-Object { [System.IO.Path]::GetFileName($_) }

    if ([string]::IsNullOrEmpty($executable)) {
        return
    }

    if ($PSCmdlet.ShouldProcess($appName, "Update volume to $($volume*100)%")) {
        & $pathToNirCmd setappvolume $executable $volume
    }
}

function Log {
    param (
        [string]$msg
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$ts - $msg"
}

Main
