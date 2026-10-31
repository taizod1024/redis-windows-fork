param(
  [Parameter(Mandatory)]
  [string]$WingetCreatePath,

  [Parameter(Mandatory)]
  [string]$PackageId,

  [Parameter(Mandatory)]
  [string]$Version,

  [Parameter(Mandatory)]
  [string]$InstallerUrl,

  [Parameter(Mandatory)]
  [string]$Token
)

$manifestRoot = Join-Path $env:RUNNER_TEMP "winget-manifest"
if ([string]::IsNullOrWhiteSpace($Token)) {
  throw "No GitHub token is available for winget submission."
}
if (Test-Path $manifestRoot) {
  Remove-Item -Path $manifestRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $manifestRoot | Out-Null

$archivePath = Join-Path $manifestRoot "redis-package.zip"
$outputDirectory = Join-Path $manifestRoot "manifests"
New-Item -ItemType Directory -Path $outputDirectory | Out-Null
Invoke-WebRequest -Uri $InstallerUrl -OutFile $archivePath
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
  $archiveEntries = @($archive.Entries | ForEach-Object { $_.FullName })
  $requiredEntries = @(
    "redis-server.exe",
    "msys-2.0.dll",
    "msys-crypto-3.dll",
    "msys-ssl-3.dll",
    "msys-gcc_s-seh-1.dll",
    "msys-stdc++-6.dll"
  )
  $missingEntries = @($requiredEntries | Where-Object { $_ -notin $archiveEntries })
  if ($missingEntries.Count -gt 0) {
    throw "ZIP must contain Redis and its runtime DLLs at the archive root. Missing: $($missingEntries -join ', ')"
  }
}
finally {
  $archive.Dispose()
}

$separatorIndex = $PackageId.IndexOf(".")
if ($separatorIndex -lt 1 -or $separatorIndex -eq $PackageId.Length - 1) {
  throw "PackageId must contain a publisher and package name separated by a period."
}

$publisher = $PackageId.Substring(0, $separatorIndex)
$packageIdentifierName = $PackageId.Substring($separatorIndex + 1)
$publisherInitial = $publisher.Substring(0, 1).ToLowerInvariant()
$packageName = "redis-windows"
$installerSha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToUpperInvariant()

$versionDirectory = Join-Path $outputDirectory "manifests"
$versionDirectory = Join-Path $versionDirectory $publisherInitial
$versionDirectory = Join-Path $versionDirectory $publisher
$versionDirectory = Join-Path $versionDirectory $packageIdentifierName
$versionDirectory = Join-Path $versionDirectory $Version
New-Item -ItemType Directory -Path $versionDirectory -Force | Out-Null

$installerManifest = @"
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.12.0.schema.json
PackageIdentifier: $PackageId
PackageVersion: $Version
InstallerType: zip
NestedInstallerType: portable
NestedInstallerFiles:
- RelativeFilePath: redis-server.exe
  PortableCommandAlias: redis-server
ArchiveBinariesDependOnPath: true
Installers:
- Architecture: x64
  Scope: user
  InstallerUrl: $InstallerUrl
  InstallerSha256: $installerSha256
- Architecture: x64
  Scope: machine
  InstallerUrl: $InstallerUrl
  InstallerSha256: $installerSha256
ManifestType: installer
ManifestVersion: 1.12.0
"@

$versionManifest = @"
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.version.1.12.0.schema.json
PackageIdentifier: $PackageId
PackageVersion: $Version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.12.0
"@

$localeManifest = @"
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.defaultLocale.1.12.0.schema.json
PackageIdentifier: $PackageId
PackageVersion: $Version
PackageLocale: en-US
Publisher: $publisher
PublisherUrl: https://github.com/$publisher
PublisherSupportUrl: https://github.com/taizod1024/redis-windows-fork/issues
PackageName: $packageName
PackageUrl: https://github.com/taizod1024/redis-windows-fork
License: MIT
LicenseUrl: https://github.com/redis-windows/redis-windows/blob/main/LICENSE
ShortDescription: Redis for Windows on MSYS2 runtime
ManifestType: defaultLocale
ManifestVersion: 1.12.0
"@

$manifestFiles = @{
  "$PackageId.installer.yaml" = $installerManifest
  "$PackageId.yaml" = $versionManifest
  "$PackageId.locale.en-US.yaml" = $localeManifest
}
$encoding = [System.Text.UTF8Encoding]::new($false)
foreach ($fileName in $manifestFiles.Keys) {
  $filePath = Join-Path $versionDirectory $fileName
  [System.IO.File]::WriteAllText($filePath, $manifestFiles[$fileName], $encoding)
}

if ($installerManifest -notmatch "(?m)^  Scope: user\r?$" -or $installerManifest -notmatch "(?m)^  Scope: machine\r?$") {
  throw "The installer manifest must include both user and machine scopes."
}

$submitArguments = @("submit", $versionDirectory, "--token", $Token, "--no-open")

& $WingetCreatePath @submitArguments
if ($LASTEXITCODE -ne 0) {
  throw "wingetcreate submit failed with exit code $LASTEXITCODE."
}
