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

$updateArguments = @(
  "update",
  $PackageId,
  "--token",
  $Token,
  "--urls",
  "$InstallerUrl|x64|user",
  "$InstallerUrl|x64|machine",
  "--version",
  $Version,
  "--out",
  $outputDirectory
)
& $WingetCreatePath @updateArguments
if ($LASTEXITCODE -ne 0) {
  throw "wingetcreate update failed with exit code $LASTEXITCODE."
}

$installerManifests = @(Get-ChildItem -Path $outputDirectory -Filter "*.installer.yaml" -Recurse)
if ($installerManifests.Count -ne 1) {
  throw "Expected one installer manifest, found $($installerManifests.Count)."
}

$installerManifest = $installerManifests[0]
$content = [System.IO.File]::ReadAllText($installerManifest.FullName)
if ($content -notmatch "(?m)^InstallerType:\s*zip\s*$") {
  throw "The generated manifest is not a ZIP installer."
}
if ($content -notmatch "(?m)^NestedInstallerType:\s*portable\s*$") {
  throw "The generated manifest is not a portable ZIP manifest."
}

$nestedInstallerFiles = @"
NestedInstallerFiles:
- RelativeFilePath: redis-server.exe
  PortableCommandAlias: redis-server
"@
$nestedInstallerPattern = "(?ms)^NestedInstallerFiles:\r?\n.*?(?=^Installers:)"
if ($content -match $nestedInstallerPattern) {
  $content = [regex]::Replace($content, $nestedInstallerPattern, "$nestedInstallerFiles`r`n", 1)
}
elseif ($content -match "(?m)^Installers:") {
  $content = [regex]::Replace($content, "(?m)^Installers:", "$nestedInstallerFiles`r`nInstallers:", 1)
}
else {
  throw "The generated manifest has no Installers section."
}

if ($content -match "(?m)^ArchiveBinariesDependOnPath:\s*.*$") {
  $content = [regex]::Replace($content, "(?m)^ArchiveBinariesDependOnPath:\s*.*$", "ArchiveBinariesDependOnPath: true")
}
else {
  $content = [regex]::Replace($content, "(?m)^ManifestType:", "ArchiveBinariesDependOnPath: true`r`nManifestType:", 1)
}

if ($content -notmatch "(?m)^\s*Scope:\s*user\s*$") {
  throw "The generated manifest is missing the user-scope installer."
}
if ($content -notmatch "(?m)^\s*Scope:\s*machine\s*$") {
  throw "The generated manifest is missing the machine-scope installer."
}

[System.IO.File]::WriteAllText(
  $installerManifest.FullName,
  $content,
  [System.Text.UTF8Encoding]::new($false)
)

& $WingetCreatePath submit --token $Token --no-open $installerManifest.DirectoryName
if ($LASTEXITCODE -ne 0) {
  throw "wingetcreate submit failed with exit code $LASTEXITCODE."
}
