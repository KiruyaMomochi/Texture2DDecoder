#!/usr/bin/env pwsh

Set-StrictMode -Version 3.0

$script:ErrorActionPreference = 'Stop'
$script:PSNativeCommandUseErrorActionPreference = $true

enum TargetSystem {
    Windows;
    Linux;
    MacOS;
}

function IOSCMakePlatforms 
{ 'OS', 'OS64', 'OS64COMBINED', 'SIMULATOR', 'SIMULATOR64', 'SIMULATORARM64', 'TVOS', 'TVOSCOMBINED', 'SIMULATOR_TVOS', 'WATCHOS', 'WATCHOSCOMBINED', 'SIMULATOR_WATCHOS', 'MAC', 'MAC_ARM64', 'MAC_CATALYST', 'MAC_CATALYST_ARM64' }

function Get-TargetSystem {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return [TargetSystem]::Windows
    }

    if ($IsLinux) {
        return [TargetSystem]::Linux
    }

    if ($IsMacOS) {
        return [TargetSystem]::MacOS
    }

    if ($IsWindows) {
        return [TargetSystem]::Windows
    }

    throw 'Unsupported OS'
}

function Get-CMakeNativeArgs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Architecture
    )
    
    $TargetSystem = (Get-TargetSystem)

    switch ($TargetSystem) {
        ([TargetSystem]::Windows) {
            switch ($architecture) {
                'x86' {
                    '-A', 'Win32'
                }
                default {
                    '-A', $architecture
                }
            }
        }
        ([TargetSystem]::MacOS) {
            switch ($architecture) {
                'x64' {
                    '-D', 'CMAKE_OSX_ARCHITECTURES="x86_64"'
                }
                'arm64' {
                    '-D', 'CMAKE_OSX_ARCHITECTURES="arm64"'
                }
                'universal' {
                    '-D', 'CMAKE_OSX_ARCHITECTURES="x86_64;arm64"'
                }
                default {
                    throw "Unsupported architecture: $architecture for $TargetSystem"
                }
            }
        }
        ([TargetSystem]::Linux) {
            switch ($architecture) {
                'x86' {
                    '-DCMAKE_CXX_FLAGS=-m32', '-DCMAKE_C_FLAGS=-m32'
                }
                'x64' {}
                default {
                    throw "Unsupported architecture: $architecture for $TargetSystem"
                }
            }
        }
        default {
            throw "Unsupported target system: $TargetSystem for $TargetSystem"
        }
    }
}

function Get-CMakeAppleArgs {
    param (
        [Parameter(Mandatory)]
        [string]
        $Platform,
        [Parameter()]
        [string]
        $Generator
    )

    $toolchain = Join-Path $PSScriptRoot ios-cmake ios.toolchain.cmake
    if (!(Test-Path $toolchain)) {
        throw "Toolchain file not found: $toolchain"
    }

    if ($Platform.EndsWith('COMBINED') -and $Generator -ne 'Xcode') {
        throw 'The COMBINED options ONLY work with the Xcode generator (-G Xcode)'
    }

    if ($Platform -eq 'iOS') {
        '-D', 'CMAKE_SYSTEM_NAME=iOS'
        '-D', 'CMAKE_OSX_ARCHITECTURES=arm64;x86_64'
        '-D', 'CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO'
        '-D', 'CMAKE_IOS_INSTALL_COMBINED=YES'
        return
    }

    '--toolchain', "$toolchain"
    '-D', "PLATFORM=$Platform"
}

function Get-CMakeAndroidArgs {
    param (        
        [Parameter(Mandatory, ParameterSetName = 'Android')]
        [ArgumentCompletions('armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64')]
        [string]
        $AndroidAbi,
        [Parameter(Mandatory, ParameterSetName = 'Android')]
        [string]
        $NdkHome,
        [Parameter(Mandatory, ParameterSetName = 'Android')]
        [int]
        $AndroidVersion,
        [Parameter()]
        [switch]
        $NdkToolchain
    )
    
    if ($NdkToolchain) {
        $toolchain = Join-Path -Resolve $NdkHome build cmake android.toolchain.cmake
        
        '-D', "ANDROID_ABI=$AndroidAbi"
        '-D', "ANDROID_PLATFORM=android-$AndroidVersion"
        '-D', "CMAKE_TOOLCHAIN_FILE=$toolchain"
        return
    }

    '-D', 'CMAKE_SYSTEM_NAME=Android'
    '-D', "CMAKE_SYSTEM_VERSION=$AndroidVersion"
    '-D', "CMAKE_ANDROID_ARCH_ABI=$AndroidAbi"
    '-D', "CMAKE_ANDROID_NDK=$NdkHome"
}

function Invoke-CMakeBuild {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $SourcePath,
        [Parameter(Mandatory, Position = 1)]
        [string]
        $BuildPath,
        [Parameter()]
        [ArgumentCompletions('Debug', 'Release')]
        [string]
        $BuildType,

        [Parameter(ParameterSetName = 'TargetSystem')]
        [ArgumentCompletions('x86', 'x64', 'arm', 'arm64', 'universal')]
        [string]
        $Architecture,

        [Parameter(Mandatory, ParameterSetName = 'AppleCMake')]
        [ArgumentCompleter({ IOSCMakePlatforms })]
        [string]
        $AppleCMake,
        [Parameter(ParameterSetName = 'AppleCMake')]
        [switch]
        $Framework,

        [Parameter(Mandatory, ParameterSetName = 'Wasm')]
        [switch]
        $Wasm,
        
        [Parameter(Mandatory, ParameterSetName = 'Android')]
        [ArgumentCompletions('armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64')]
        [string]
        $AndroidAbi,
        [Parameter(ParameterSetName = 'Android')]
        [string]
        $NdkHome = $env:ANDROID_NDK_HOME,
        [Parameter(ParameterSetName = 'Android')]
        [int]
        $AndroidVersion = 19,
        [Parameter(ParameterSetName = 'Android')]
        [switch]
        $NdkToolchain,

        [Parameter()]
        [string]
        $Generator,
        [Parameter()]
        [switch]
        $Static,

        [Parameter()]
        [switch]
        $CleanFirst,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $RemainingArguments
    )

    if (-not $BuildType) {
        if ($env:BUILD_TYPE) {
            $BuildType = $env:BUILD_TYPE
        }
        else {
            $BuildType = 'Release'
        }
    }

    if (! (Test-Path $SourcePath)) { $null = New-Item -ItemType Directory -Path $SourcePath -Force }
    if (! (Test-Path $BuildPath)) { $null = New-Item -ItemType Directory -Path $BuildPath -Force }

    if ($CleanFirst) {
        if (Test-Path $BuildPath) { $null = Remove-Item -Path $BuildPath -Recurse -Force }
        $null = New-Item -ItemType Directory -Path $BuildPath -Force
    }

    $confArgs = @()
    $confArgs += $sourcePath
    $confArgs += "-B$BuildPath"
    $confArgs += "-DCMAKE_BUILD_TYPE=$BuildType"

    if ($Architecture) {
        $confArgs += Get-CMakeNativeArgs -Architecture $Architecture
    }

    if ($AppleCMake) {
        if (-not $Generator) {
            $Generator = 'Xcode'
        }
        
        $confArgs += Get-CMakeAppleArgs -Platform $AppleCMake -Generator $Generator
    }

    if ($AndroidAbi) {
        $confArgs += Get-CMakeAndroidArgs -AndroidAbi $AndroidAbi -NdkHome $NdkHome -AndroidVersion $AndroidVersion -NdkToolchain:$NdkToolchain
        if (-not $Generator -and $IsWindows) {
            $Generator = 'Ninja'
        }
    }

    if ($Generator) {
        $confArgs += '-G', $Generator
    }

    if ($Static) {
        $confArgs += '-DBUILD_SHARED_LIBS=OFF'
    }

    if ($FRAMEWORK) {
        $confArgs += '-DBUILD_FRAMEWORK=TRUE'
    }

    $confArgs += $RemainingArguments

    if ($PSCmdlet.ShouldProcess('cmake', $confArgs)) {
        if ($Wasm) {
            Write-Output ($PSStyle.Foreground.Cyan + "Configure with emcmake and args: $confArgs" + $PSStyle.Reset)
            emcmake cmake @confArgs
        }
        else {
            Write-Output ($PSStyle.Foreground.Cyan + "Configure with args: $confArgs" + $PSStyle.Reset)
            cmake @confArgs
        }
        if (-not $?) { throw 'cmake configure failed' }
    }

    $buildArgs = @()
    $buildArgs += '--build', $BuildPath
    $buildArgs += '--config', $BuildType

    Write-Output ($PSStyle.Foreground.Green + "Build with args: $buildArgs" + $PSStyle.Reset)
    if ($PSCmdlet.ShouldProcess('cmake', $buildArgs)) {
        cmake @buildArgs
        if (-not $?) { throw 'cmake build failed' }
    }
}

function Invoke-CMakeInstall {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $BuildPath,
        [Parameter(Position = 1)]
        [string]
        $Prefix,
        [Parameter()]
        [ArgumentCompletions('Debug', 'Release')]
        [string]
        $BuildType
    )

    $installArgs = @('--install', $BuildPath)
    
    if ($Prefix) {
        if (!(Test-Path $Prefix)) { $null = New-Item -ItemType Directory -Path $Prefix -Force }
        $Prefix = Resolve-Path $Prefix

        $installArgs += '--prefix', $Prefix
    }

    if (-not $BuildType) {
        if ($env:BUILD_TYPE) {
            $BuildType = $env:BUILD_TYPE
        }
        else {
            $BuildType = 'Release'
        }
    }

    if ($BuildType) {
        $installArgs += '--config', $BuildType
    }

    if ($PSCmdlet.ShouldProcess('cmake', $installArgs)) {
        Write-Output ($PSStyle.Foreground.BrightMagenta + "Install with args: $installArgs" + $PSStyle.Reset)
        cmake @installArgs
        if (-not $?) { throw 'cmake install failed' }
    }
}

function Invoke-CMakeAppleBatchBuild {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $SourcePath,
        [Parameter(Mandatory, Position = 1)]
        [string]
        $BuildPrefix,
        [Parameter(Mandatory)]
        [string[]]
        $Platforms,
        [Parameter()]
        [ArgumentCompletions('Debug', 'Release')]
        [string]
        $BuildType,
        [Parameter()]
        [string]
        $Generator,
        [Parameter()]
        [switch]
        $Static,
        [Parameter()]
        [switch]
        $CleanFirst,
        [switch]
        $Framework,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $RemainingArguments
    )

    $params = [hashtable]::new($PSBoundParameters)
    $params.Remove('Platforms')
    $params.Remove('BuildPrefix')

    foreach ($platform in $Platforms) {        
        $buildPath = "$BuildPrefix-$platform"
        Invoke-CMakeBuild -SourcePath $SourcePath -BuildPath $buildPath -AppleCMake $platform @params
    }
}

function Invoke-CMakeAndroidBatchBuild {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $SourcePath,
        [Parameter(Mandatory, Position = 1)]
        [string]
        $BuildPrefix,
        [Parameter(Mandatory)]
        [string[]]
        $AndroidAbis,
        [string]
        $NdkHome = $env:ANDROID_NDK_HOME,
        [int]
        $AndroidVersion = 19,
        [Parameter()]
        [ArgumentCompletions('Debug', 'Release')]
        [string]
        $BuildType,
        [Parameter()]
        [string]
        $Generator,
        [Parameter()]
        [switch]
        $Static,
        [Parameter()]
        [switch]
        $CleanFirst,
        [Parameter()]
        [switch]
        $NdkToolchain,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $RemainingArguments
    )

    $params = [hashtable]::new($PSBoundParameters)
    $params.Remove('AndroidAbis')
    $params.Remove('BuildPrefix')

    foreach ($abi in $AndroidAbis) {        
        $buildPath = "$BuildPrefix-$abi"
        Invoke-CMakeBuild -SourcePath $SourcePath -BuildPath $buildPath -AndroidAbi $abi @params
    }
}

function Invoke-CMakeNativeBatchBuild {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $SourcePath,
        [Parameter(Mandatory, Position = 1)]
        [string]
        $BuildPrefix,
        [Parameter(Mandatory)]
        [string[]]
        $Architectures,
        [Parameter()]
        [ArgumentCompletions('Debug', 'Release')]
        [string]
        $BuildType,
        [Parameter()]
        [string]
        $Generator,
        [Parameter()]
        [switch]
        $Static,
        [Parameter()]
        [switch]
        $CleanFirst,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $RemainingArguments
    )

    $params = [hashtable]::new($PSBoundParameters)
    $params.Remove('Architectures')
    $params.Remove('BuildPrefix')

    foreach ($architechure in $Architectures) {        
        $buildPath = "$BuildPrefix-$architechure"
        Invoke-CMakeBuild -SourcePath $SourcePath -BuildPath $buildPath -Architecture $architechure @params
    }
}

function Invoke-CMakeAppleBatchInstall {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $BuildPrefix,
        [Parameter(Position = 1)]
        [string]
        $InstallPrefix,
        [Parameter(Mandatory)]
        [string[]]
        $Platforms,
        [Parameter()]
        [AllowEmptyString()]
        [string]
        $Merge,
        [Parameter()]
        [ArgumentCompletions('Debug', 'Release')]
        [string]
        $BuildType
    )
    
    $installedLibs = @{}

    foreach ($platform in $Platforms) {        
        $buildPath = "$BuildPrefix-$platform"
        $prefix = "$InstallPrefix-$platform"
        if (Test-Path $prefix) { $null = Remove-Item -Recurse -Force -Path $prefix }

        Invoke-CMakeInstall -BuildPath $buildPath -Prefix $prefix -BuildType $BuildType

        Get-ChildItem $prefix -File -Recurse | ForEach-Object {
            if ($_.Name.EndsWith('.a') -or $_.Name.EndsWith('.dylib')) {
                $libraryPlatform = otool -l $_.FullName |
                Select-String 'platform (\d+)' |
                Foreach-Object { $_[0].Matches[0].Groups[1].Value }
                if ($platform.Contains('CATALYST') -and $libraryPlatform -ne '6') {
                    throw "Library platform mismatch: $libraryPlatform != 6"
                }
            }
        }

        Get-ChildItem $prefix -File -Recurse | ForEach-Object {
            $installedLibs[$_.Name] ??= @()
            $installedLibs[$_.Name] += $_
        }
    }

    if (-not $Merge) { return }

    $installPath = "$InstallPrefix-$Merge"
    if (Test-Path $installPath) {
        Remove-Item -Recurse -Force $installPath
    }
    $null = New-Item -Force (Join-Path $installPath lib) -ItemType Directory

    foreach ($lib in $installedLibs.Keys) {
        if ($lib.EndsWith('.dylib') -or $lib.EndsWith('.a')) { 
            if ($PSCmdlet.ShouldProcess('lipo', $lib)) {
                $dest = Join-Path $installPath lib $lib
                Write-Output ($PSStyle.Foreground.Yellow + "Merging: $dest" + $PSStyle.Reset)
                lipo -create -output $dest ($installedLibs[$lib]) 
            }
        }
    }
}


function Invoke-CMakeAndroidBatchInstall {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $BuildPrefix,
        [Parameter(Position = 1)]
        [string]
        $InstallPrefix,
        [Parameter(Mandatory)]
        [string[]]
        $AndroidAbis,
        [Parameter()]
        [switch]
        $Merge,
        [Parameter()]
        [ArgumentCompletions('Debug', 'Release')]
        [string]
        $BuildType
    )

    $installedLibs = @{}

    foreach ($abi in $AndroidAbis) {        
        $buildPath = "$BuildPrefix-$abi"
        $prefix = "$InstallPrefix-$abi"
        if (Test-Path $prefix) { $null = Remove-Item -Recurse -Force -Path $prefix }

        Invoke-CMakeInstall -BuildPath $buildPath -Prefix $prefix -BuildType $BuildType

        Get-ChildItem $prefix -File -Recurse | ForEach-Object {
            $installedLibs[$_.Name] ??= @()
            $installedLibs[$_.Name] += $_
        }
    }
}

function Invoke-CMakeNativeBatchInstall {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $BuildPrefix,
        [Parameter(Position = 1)]
        [string]
        $InstallPrefix,
        [Parameter(Mandatory)]
        [string[]]
        $Architectures,
        [Parameter()]
        [switch]
        $Merge,
        [Parameter()]
        [ArgumentCompletions('Debug', 'Release')]
        [string]
        $BuildType
    )

    $installedLibs = @{}


    foreach ($architecture in $Architectures) {        
        $buildPath = "$BuildPrefix-$architecture"
        $prefix = "$InstallPrefix-$architecture"
        if (Test-Path $prefix) { $null = Remove-Item -Recurse -Force -Path $prefix }

        Invoke-CMakeInstall -BuildPath $buildPath -Prefix $prefix -BuildType $BuildType

        Get-ChildItem $prefix -File -Recurse | ForEach-Object {
            $installedLibs[$_.Name] ??= @()
            $installedLibs[$_.Name] += $_
        }
    }
}
