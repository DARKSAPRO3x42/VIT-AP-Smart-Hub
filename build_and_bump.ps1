<#
.SYNOPSIS
Bumps the version in pubspec.yaml and builds the Flutter APK.

.DESCRIPTION
This script reads the current version from pubspec.yaml, increments the patch version
(e.g., 1.0.0 -> 1.0.1) and the build number (e.g., +1 -> +2). It saves the file and then
runs `flutter build apk`.

.EXAMPLE
.\build_and_bump.ps1
#>

$pubspecPath = "pubspec.yaml"

if (-Not (Test-Path $pubspecPath)) {
    Write-Host "Error: pubspec.yaml not found in current directory." -ForegroundColor Red
    exit 1
}

$content = Get-Content $pubspecPath

# Regex to find `version: X.Y.Z+B`
$versionRegex = "^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)"

$newContent = @()
$versionUpdated = $false
$newVersionString = ""

foreach ($line in $content) {
    if ($line -match $versionRegex) {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        $patch = [int]$matches[3]
        $buildNumber = [int]$matches[4]

        # Increment patch and build number
        $newPatch = $patch + 1
        $newBuildNumber = $buildNumber + 1
        
        $newVersionString = "version: $major.$minor.$newPatch+$newBuildNumber"
        $newContent += $newVersionString
        $versionUpdated = $true
        Write-Host "Bumped version from $($matches[0]) to $newVersionString" -ForegroundColor Green
    } else {
        $newContent += $line
    }
}

if (-Not $versionUpdated) {
    Write-Host "Error: Could not find a valid version string in pubspec.yaml to bump. Make sure it is formatted as 'version: X.Y.Z+B'" -ForegroundColor Red
    exit 1
}

# Write changes back to pubspec.yaml
$newContent | Set-Content $pubspecPath -Encoding UTF8

Write-Host "Starting Flutter build..." -ForegroundColor Cyan
flutter build apk

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build finished successfully! The new version is $newVersionString." -ForegroundColor Green
    Write-Host "The APK is located at: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
} else {
    Write-Host "Flutter build failed." -ForegroundColor Red
}
