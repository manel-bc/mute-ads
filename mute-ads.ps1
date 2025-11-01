function Main {
    while ($true) {
        if (Is-App-Playing-Ads) {
            Change-App-Volume 0
            continue
        }

        Change-App-Volume 1
        Start-Sleep -Milliseconds 500
    }
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

$configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content $configFile -Raw | ConvertFrom-Json

Main
