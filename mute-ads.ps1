$global:config = $null

function Main {
    Read-Config

    Log "Looking for advertisements..."
    while ($true) {
        if (Is-App-Playing-Ads) {
            Log "Advertisment detected"
            Change-App-Volume 0
            continue
        }

        Change-App-Volume 1
        Start-Sleep -Milliseconds 500
    }
}

function Read-Config {
    Log "Reading config"
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
    $global:config = Get-Content $configFile -Raw | ConvertFrom-Json
}

function Is-App-Playing-Ads {
    Get-Process $config.applicationName -ErrorAction SilentlyContinue |
        ForEach-Object { 
            if ($_.MainWindowTitle -like "*Advertisement*") {
                return $true
            }
        }
       
    return $false
}

function Change-App-Volume {
    param (
        [float]$volume
    )

    $executable = Get-Process $config.applicationName -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty Path |
        ForEach-Object { [System.IO.Path]::GetFileName($_) }

    if ([string]::IsNullOrEmpty($executable)) {
        return
    }

    & $config.pathToNirCmd setappvolume $executable $volume
}

function Log {
    param (
        [string]$msg
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$ts - $msg"
}

Main
