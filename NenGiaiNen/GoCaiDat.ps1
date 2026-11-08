# GO CAI DAT: xoa menu chuot phai va bieu tuong Desktop.
$HKCU = [Microsoft.Win32.Registry]::CurrentUser
$DuoiNen = @('.zip', '.rar', '.7z', '.tar', '.gz', '.tgz', '.bz2', '.tbz2', '.xz', '.txz', '.cab', '.iso')
$ds = @('Software\Classes\*\shell\NenGiaiNen.Nen', 'Software\Classes\Directory\shell\NenGiaiNen.Nen')
foreach ($d in $DuoiNen) { $ds += ('Software\Classes\SystemFileAssociations\' + $d + '\shell\NenGiaiNen.GiaiNen') }
foreach ($k in $ds) { try { $HKCU.DeleteSubKeyTree($k, $false) } catch { } }

foreach ($noi in @([Environment]::GetFolderPath('SendTo'), [Environment]::GetFolderPath('Desktop'))) {
    Get-ChildItem -LiteralPath $noi -Filter '*.lnk' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'N*n th*nh ZIP.lnk' -or $_.Name -like 'Gi*i n*n t*i *.lnk' -or $_.Name -like 'N*n - Gi*i n*n*.lnk' } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
Write-Host 'Da go menu chuot phai va bieu tuong Desktop.' -ForegroundColor Green

$khoaW11 = 'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
if ($HKCU.OpenSubKey($khoaW11 + '\InprocServer32')) {
    $tl = Read-Host 'Tra menu chuot phai Windows 11 ve kieu moi (thu gon)? Go C (Co) hoac K (Khong) roi Enter'
    if ($tl -match '^\s*[cCyY]') {
        try { $HKCU.DeleteSubKeyTree($khoaW11, $false) } catch { }
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
        Write-Host 'Da tra ve menu kieu Windows 11.'
    }
}
