#!/usr/bin/env pwsh
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $EmsdkPath
)
$dotnetVersion = (dotnet --version).Split('.')
if ($dotnetVersion[-1].Length -eq 3) {
$dotnetVersion[-1] = $dotnetVersion[-1][0]
}
$dotnetVersion = $dotnetVersion -join '.'
$emsdkVersion = (Invoke-WebRequest https://github.com/dotnet/runtime/raw/v$dotnetVersion/src/mono/wasm/emscripten-version.txt).Content

Write-Host "Using emsdk $emsdkVersion for dotnet $dotnetVersion"

Set-Location $EmsdkPath
./emsdk install $emsdkVersion
./emsdk activate $emsdkVersion
