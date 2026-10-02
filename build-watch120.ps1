# build-watch120.ps1 - heartbeat watcher for the v1.2.0 rebuild (bg pid 104352).
# Emits one line per 60s while the build process is alive (log size + tail line),
# then a terminal marker when it exits. Used by the Qwen Code monitor tool.
$Log = 'C:\Users\Morawake\ninfer-4090\build-v120.log'
$Pid = 104352
while (Get-Process -Id $Pid -ErrorAction SilentlyContinue) {
    $l = 0
    $t = ''
    if (Test-Path $Log) {
        $l = (Get-Item $Log).Length
        $t = (Get-Content $Log -Tail 1)
    }
    Write-Host ("alive " + [math]::Floor($l / 1048576) + "MB: " + $t)
    Start-Sleep -Seconds 60
}
$last = ''
if (Test-Path $Log) { $last = (Get-Content $Log -Tail 5) -join ' | ' }
Write-Host "BUILD PROCESS EXITED. tail: $last"