#!/usr/bin/env pwsh
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $EmsdkPath
)

Set-Location $EmsdkPath
./emsdk install latest
./emsdk activate latest
