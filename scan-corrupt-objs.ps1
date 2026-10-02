# Scan COFF .obj files under the ninja build tree; delete any whose structure
# does not parse cleanly (truncated mid-write during the 2026-09-12 hard crash).
$root = 'C:\Users\Morawake\ninfer-4090\build-ninja'
$objs = Get-ChildItem -Path $root -Recurse -Filter *.obj -File | Sort-Object FullName
$bad = @()
foreach ($f in $objs) {
    $size = $f.Length
    $ok = $true
    if ($size -lt 40) { $ok = $false }
    else {
        $fs = [System.IO.File]::OpenRead($f.FullName)
        try {
            $br = New-Object System.IO.BinaryReader($fs)
            $machine = $br.ReadUInt16()    # 0x8664 = x64
            $nsec = $br.ReadUInt16()
            [void]$br.ReadUInt32()         # TimeDateStamp
            $ptrSym = $br.ReadUInt32()
            $numSym = $br.ReadUInt32()
            [void]$br.ReadUInt16()         # SizeOfOptionalHeader
            [void]$br.ReadUInt16()         # Characteristics
            if ($machine -ne 0x8664) { $ok = $false }
            if ($ok -and $size -lt 20 + $nsec * 80) { $ok = $false }
            if ($ok -and $ptrSym -gt 0 -and $numSym -gt 0) {
                if ($size -lt $ptrSym + $numSym * 18) { $ok = $false }
            }
            for ($i = 0; $ok -and $i -lt $nsec; $i++) {
                [void]$br.ReadBytes(8)     # Name
                [void]$br.ReadUInt32()     # VirtualSize
                [void]$br.ReadUInt32()     # VirtualAddress
                $rawSize = $br.ReadUInt32()
                $rawPtr = $br.ReadUInt32()
                [void]$br.ReadBytes(56)    # rest of the 80-byte section header
                if ($rawSize -gt 0 -and $size -lt $rawPtr + $rawSize) { $ok = $false }
            }
        } catch { $ok = $false }
        finally { $fs.Close() }
    }
    if (-not $ok) { $bad += $f.FullName }
}
Write-Output ("Scanned {0} obj files, {1} corrupt." -f $objs.Count, $bad.Count)
foreach ($b in $bad) {
    Write-Output "DELETE: $b"
    Remove-Item -LiteralPath $b -Force
}