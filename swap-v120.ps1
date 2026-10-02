# swap-v120.ps1 - one-shot v1.2.0 deployment (2026-09-12)
# 1. stop the whole ninfer stack (servers + stray watchdogs),
# 2. copy the rebuilt ninfer-serve.exe + any differing runtime DLLs into the
#    install dir,
# 3. verify the installed exe is the new build.
# Relaunch afterwards via scripts\restart-ninfer-serve.bat (starts the watchdog).
$ErrorActionPreference = 'Stop'
$Build = 'C:\Users\Morawake\ninfer-4090\build-ninja\apps'
$Dst   = 'C:\Everything\Programs\Ninfer-4090'

Write-Host '== 1. stop stack =='
powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Everything\Vaults\Fold\scripts\kill-ninfer-stack.ps1'
for ($i = 0; $i -lt 15; $i++) {
    if (-not (Get-Process ninfer-serve -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Seconds 1
}
if (Get-Process ninfer-serve -ErrorAction SilentlyContinue) {
    throw 'ninfer-serve still alive after kill - aborting, nothing deployed'
}
Write-Host 'stack stopped'

# The killed server's exe image can stay FILE-LOCKED for several seconds after
# the process disappears (GPU context teardown for a CUDA app killed mid-request,
# console hosts dying, AV scan). 2026-09-12: the copy failed ~3 s post-kill.
# Wait until we can exclusively open the file before copying.
$target = Join-Path $Dst 'ninfer-serve.exe'
$free = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        $fs = [System.IO.File]::Open($target, 'Open', 'ReadWrite', 'None')
        $fs.Close()
        $free = $true
        break
    } catch [System.IO.IOException] {
        Write-Host ("exe still locked, waiting ({0} s)..." -f $i)
        Start-Sleep -Seconds 1
    }
}
if (-not $free) { throw 'ninfer-serve.exe stayed file-locked for 60 s - aborting, nothing deployed' }

Write-Host '== 2. deploy artifacts =='
$exeNew = Get-Item (Join-Path $Build 'ninfer-serve.exe')
Write-Host ("new exe from build: {0} bytes" -f $exeNew.Length)
Copy-Item $exeNew.FullName (Join-Path $Dst 'ninfer-serve.exe') -Force

$dstDl = @{}
Get-ChildItem $Dst -Filter *.dll -ErrorAction SilentlyContinue | ForEach-Object { $dstDl[$_.Name] = $_ }
foreach ($dll in (Get-ChildItem $Build -Filter *.dll)) {
    $t = $dstDl[$dll.Name]
    if (-not $t) {
        Write-Host ("copy new dll: {0} ({1} bytes)" -f $dll.Name, $dll.Length)
        Copy-Item $dll.FullName $Dst -Force
    } elseif ($t.Length -ne $dll.Length) {
        Write-Host ("dll differs, updating: {0} ({1} -> {2} bytes)" -f $dll.Name, $t.Length, $dll.Length)
        Copy-Item $dll.FullName $Dst -Force
    }
}

Write-Host '== 3. verify =='
$chk = Get-Item (Join-Path $Dst 'ninfer-serve.exe')
if ($chk.Length -ne $exeNew.Length) {
    throw ("swap verify FAILED: installed {0} != build {1}" -f $chk.Length, $exeNew.Length)
}
Write-Host ("OK: installed ninfer-serve.exe = {0} bytes" -f $chk.Length)
Get-ChildItem $Dst -Filter *.dll | Sort-Object Name | ForEach-Object {
    Write-Host ("  dll: {0} ({1} bytes)" -f $_.Name, $_.Length)
}
Write-Host '== done - relaunch via restart-ninfer-serve.bat =='