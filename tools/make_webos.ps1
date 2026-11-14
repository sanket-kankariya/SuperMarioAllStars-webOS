# PowerShell build script for webOS
param (
    [string]$NdkPath = $env:ANDROID_NDK_ROOT,
    [string]$SysrootPath = $env:WEBOS_SYSROOT
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir

Write-Host "=== Super Mario All-Stars webOS Build ===" -ForegroundColor Cyan

# Check for ROM
if (-not (Test-Path "rom\smas.sfc")) {
    Write-Error "ROM file not found at rom\smas.sfc. Please copy your Super Mario All-Stars (USA) .sfc file to rom\smas.sfc"
    exit 1
}

$BuildDir = "build_webos"
$StageDir = "$BuildDir\stage"
$OutDir = "out"

New-Item -ItemType Directory -Path $BuildDir, $StageDir, $OutDir -Force | Out-Null

$CmakeArgs = @(
    "-S", ".",
    "-B", $BuildDir,
    "-G", "Ninja",
    "-DCMAKE_TOOLCHAIN_FILE=cmake/webos_toolchain.cmake",
    "-DCMAKE_BUILD_TYPE=Release"
)

if ($NdkPath) { $CmakeArgs += "-DNDK_PATH=$NdkPath" }
if ($SysrootPath) { $CmakeArgs += "-DWEBOS_SYSROOT=$SysrootPath" }

Write-Host "Configuring CMake..." -ForegroundColor Yellow
& cmake @CmakeArgs

Write-Host "Building with ThinLTO..." -ForegroundColor Yellow
& ninja -C $BuildDir SuperMarioAllStarsRecomp

Write-Host "Staging files..." -ForegroundColor Yellow
Copy-Item "$BuildDir\SuperMarioAllStarsRecomp" -Destination "$StageDir\SuperMarioAllStars" -Force
Copy-Item "webos\appinfo.json", "webos\package.properties", "webos\config.ini", "webos\icon.png", "webos\largeIcon.png" -Destination $StageDir -Force
Copy-Item "rom\smas.sfc" -Destination "$StageDir\smas.sfc" -Force
New-Item -ItemType Directory -Path "$StageDir\saves" -Force | Out-Null

Write-Host "Packaging IPK..." -ForegroundColor Yellow
& ares-package -o $OutDir $StageDir

Write-Host "Normalizing IPK..." -ForegroundColor Yellow
& python tools\normalize_ipk.py

Write-Host "=== Build Complete! Package ready in $OutDir\ ===" -ForegroundColor Green
