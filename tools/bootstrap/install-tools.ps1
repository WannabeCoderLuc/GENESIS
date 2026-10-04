# Installs the hash-pinned developer binaries listed in tools.lock.json into tools/bin (git-ignored).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/bootstrap/install-tools.ps1 [-Only rojo,selene]
#
# Safety: each archive is downloaded from its pinned URL and REJECTED unless its SHA-256 equals the lock entry.
# Already-installed tools whose --version output matches the pin are left untouched (idempotent).
param(
    [string[]]$Only = @()
)
$ErrorActionPreference = "Stop"

if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
    throw "tools.lock.json pins windows-x86_64 assets; this machine is $($env:PROCESSOR_ARCHITECTURE)."
}

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$BinDir = Join-Path $Root "tools\bin"
$Lock = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot "tools.lock.json") | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

foreach ($tool in $Lock.tools) {
    if ($Only.Count -gt 0 -and ($Only -notcontains $tool.name)) { continue }
    $exe = Join-Path $BinDir $tool.exe

    if (Test-Path $exe) {
        $installed = (& $exe @($tool.versionArgs) 2>&1) -join " "
        if ($installed -match [regex]::Escape($tool.versionMatch)) {
            Write-Host "$($tool.name) $($tool.version) already installed ($installed)"
            continue
        }
    }

    $zip = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetFileName($tool.url))
    Write-Host "Downloading $($tool.name) $($tool.version) ($($tool.sizeBytes) bytes) from $($tool.url)"
    Invoke-WebRequest -UseBasicParsing -Uri $tool.url -OutFile $zip

    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
    if ($actual -ne $tool.sha256) {
        Remove-Item -Force $zip
        throw "SHA-256 mismatch for $($tool.name): expected $($tool.sha256) actual $actual"
    }

    Expand-Archive -Force -LiteralPath $zip -DestinationPath $BinDir
    Remove-Item -Force $zip
    Write-Host ("Installed: " + ((& $exe @($tool.versionArgs) 2>&1) -join " "))
}
