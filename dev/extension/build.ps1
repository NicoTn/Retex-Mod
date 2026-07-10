# Build retexlink_x64.dll for Arma 3 (64-bit client -> arma3_x64.exe).
#
# Tries MSVC (cl.exe) first, then MinGW-w64 (g++). Run from a "x64 Native Tools
# Command Prompt for VS" for the MSVC path, or with MinGW's g++ on PATH.
#
#   powershell -ExecutionPolicy Bypass -File build.ps1
#
# Output: retexlink_x64.dll  (copy next to arma3_x64.exe, alongside CBA).

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

$cl  = (Get-Command cl.exe  -ErrorAction SilentlyContinue)
$gpp = (Get-Command g++.exe -ErrorAction SilentlyContinue)

if ($cl) {
    Write-Host "Building with MSVC (cl.exe) ..." -ForegroundColor Cyan
    & cl.exe /nologo /LD /O2 /EHsc /DUNICODE /D_UNICODE retexlink.cpp `
        /Fe:retexlink_x64.dll /link /DEF:retexlink.def Shlwapi.lib
    if ($LASTEXITCODE -ne 0) { throw "cl.exe failed ($LASTEXITCODE)" }
}
elseif ($gpp) {
    Write-Host "Building with MinGW-w64 (g++) ..." -ForegroundColor Cyan
    # Verify a 64-bit g++; Arma x64 needs a 64-bit DLL.
    $arch = (& g++ -dumpmachine)
    if ($arch -notmatch "x86_64") { Write-Warning "g++ target is '$arch' - need an x86_64 (64-bit) g++ for Arma x64." }
    & g++ -shared -O2 -static -static-libgcc -static-libstdc++ `
        -o retexlink_x64.dll retexlink.cpp retexlink.def -lshlwapi
    if ($LASTEXITCODE -ne 0) { throw "g++ failed ($LASTEXITCODE)" }
}
else {
    Write-Error @"
No C++ compiler found on PATH.
Install ONE of:
  - Visual Studio Build Tools (C++ workload), then run this from
    'x64 Native Tools Command Prompt for VS', or
  - MSYS2 / MinGW-w64, then put its 64-bit g++ on PATH.
Then re-run: powershell -ExecutionPolicy Bypass -File build.ps1
"@
    exit 1
}

if (Test-Path "$here\retexlink_x64.dll") {
    Write-Host "OK -> $here\retexlink_x64.dll" -ForegroundColor Green
    Write-Host "Copy it next to arma3_x64.exe (same folder as the game exe)."
}
