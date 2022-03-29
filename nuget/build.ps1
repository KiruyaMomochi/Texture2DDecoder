[CmdletBinding()]
param (
    [Parameter()]
    [Alias("o")]
    [string]
    $OutputDir = "package",
    [Parameter()]
    [ValidateScript({
        Get-ChildItem .\nuget\*.csproj | ForEach-Object BaseName
    })]
    [string[]]
    $Variants = (Get-ChildItem .\nuget\*.csproj | ForEach-Object BaseName),
    [Parameter()]
    [string]
    $Suffix = (Get-Date -UFormat "alpha.%s"),
    [Parameter()]
    [switch]
    $Push,
    [Parameter()]
    [string]
    $Source = "nuget.org"
)

$null = New-Item -ItemType Directory -Force -Path $OutputDir
$outputs = $Variants | ForEach-Object {Join-Path $OutputDir Kyaru.Texture2DDecoder.$_.*.nupkg}

Write-Output ($PSStyle.Foreground.Cyan + "Building $Variants" + $PSStyle.Reset)

# Remove old packages
foreach ($output in $outputs) {
    Get-ChildItem $output | Remove-Item -Recurse -Force 
}

# Build packages
foreach ($variant in $Variants) {
    dotnet pack (Join-Path $PSScriptRoot "$variant.csproj") --version-suffix $Suffix --configuration Release --output package
}

# Push packages
if ($Push) {
    foreach ($output in $outputs) {
        Get-ChildItem $output | ForEach-Object { dotnet nuget push $_ --source $Source }
    }
}
