$shas = '8093c640','51bf3597','02d0976d','f0eb3ac7','e51b585c','ce50e995','fd3f5d80','21a0e85f','4ac73c47','1fc1cb76'
Set-Location C:\Users\Morawake\ninfer-4090
foreach ($s in $shas) {
    $base = (& git rev-parse "$s^" 2>$null | Select-Object -First 1)
    $out = & git merge-tree --write-tree --merge-base=$base HEAD $s 2>&1
    $code = $LASTEXITCODE
    Write-Host "===== [$s] exit=$code base=$base"
    if ($code -ne 0) {
        # print info/conflict lines (skip the leading tree oid line)
        $out | Select-Object -Skip 1 | ForEach-Object { Write-Host "   $_" }
    }
}