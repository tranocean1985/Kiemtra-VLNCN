# CAI DAT: them "Nén thành ZIP" / "Giải nén tại đây" vao menu chuot phai + bieu tuong Desktop.
# Chi ghi vao nhanh HKCU (tai khoan hien tai) -> KHONG can quyen Admin.
$ErrorActionPreference = 'Stop'
$ps1   = Join-Path $PSScriptRoot 'NenGiaiNen.ps1'
$psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$icon  = Join-Path $env:SystemRoot 'System32\zipfldr.dll'
$DuoiNen = @('.zip', '.rar', '.7z', '.tar', '.gz', '.tgz', '.bz2', '.tbz2', '.xz', '.txz', '.cab', '.iso')
$HKCU = [Microsoft.Win32.Registry]::CurrentUser

function Dat-Menu([string]$khoa, [string]$chu, [string]$cheDo) {
    $k = $HKCU.CreateSubKey($khoa)
    $k.SetValue('', $chu)
    $k.SetValue('MUIVerb', $chu)
    $k.SetValue('Icon', $icon + ',0')
    $k.SetValue('MultiSelectModel', 'Player')
    $k.Close()
    $c = $HKCU.CreateSubKey($khoa + '\command')
    $c.SetValue('', ('"{0}" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "{1}" {2} "%1"' -f $psExe, $ps1, $cheDo))
    $c.Close()
}

# 1) Menu chuot phai
Dat-Menu 'Software\Classes\*\shell\NenGiaiNen.Nen'         'Nén thành ZIP' 'Nen'
Dat-Menu 'Software\Classes\Directory\shell\NenGiaiNen.Nen' 'Nén thành ZIP' 'Nen'
foreach ($d in $DuoiNen) {
    Dat-Menu ('Software\Classes\SystemFileAssociations\' + $d + '\shell\NenGiaiNen.GiaiNen') 'Giải nén tại đây' 'GiaiNen'
}

# 2) Xoa cac loi tat "Send to" cu (ban truoc)
$sendTo = [Environment]::GetFolderPath('SendTo')
Get-ChildItem -LiteralPath $sendTo -Filter '*.lnk' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'N*n th*nh ZIP.lnk' -or $_.Name -like 'Gi*i n*n t*i *.lnk' -or $_.Name -like 'N*n - Gi*i n*n*.lnk' } |
    Remove-Item -Force -ErrorAction SilentlyContinue

# 3) Bieu tuong Desktop (WScript.Shell khong ghi duoc ten co dau -> ghi ten tam roi doi ten)
$desktop = [Environment]::GetFolderPath('Desktop')
$sh  = New-Object -ComObject WScript.Shell
$tam = Join-Path $desktop ('NenGiaiNen_tam_' + [guid]::NewGuid().ToString('N') + '.lnk')
$dichLnk = Join-Path $desktop 'Nén - Giải nén.lnk'
$lnk = $sh.CreateShortcut($tam)
$lnk.TargetPath = $psExe
$lnk.Arguments = ('-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "{0}"' -f $ps1)
$lnk.WorkingDirectory = $PSScriptRoot
$lnk.IconLocation = $icon + ',0'
$lnk.WindowStyle = 7
$lnk.Save()
if (Test-Path -LiteralPath $dichLnk) { Remove-Item -LiteralPath $dichLnk -Force }
[IO.File]::Move($tam, $dichLnk)

Write-Host ''
Write-Host 'DA CAI DAT XONG:' -ForegroundColor Green
Write-Host ' - Chuot phai vao file / thu muc  -> "Nen thanh ZIP"'
Write-Host ' - Chuot phai vao file .zip/.rar/.7z... -> "Giai nen tai day"'
Write-Host ' - Desktop: bieu tuong "Nen - Giai nen"'
Write-Host ''

# 4) Windows 11: menu moi an cac muc cua phan mem vao "Show more options"
$build = [Environment]::OSVersion.Version.Build
$khoaW11 = 'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
if ($build -ge 22000 -and -not $HKCU.OpenSubKey($khoaW11)) {
    Write-Host 'Windows 11 an cac muc tren vao "Show more options" (Hien them tuy chon).'
    Write-Host 'Co the bat menu chuot phai DAY DU (kieu Windows 10) de thay ngay, giong WinRAR/7-Zip.'
    $tl = Read-Host 'Bat menu chuot phai day du? Go C (Co) hoac K (Khong) roi Enter'
    if ($tl -match '^\s*[cCyY]') {
        $k = $HKCU.CreateSubKey($khoaW11); $k.SetValue('', ''); $k.Close()
        Write-Host 'Dang khoi dong lai Windows Explorer...'
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
        Write-Host 'Xong. Menu chuot phai da hien day du.' -ForegroundColor Green
    }
}
Write-Host ''
Write-Host 'Luu y: KHONG di chuyen thu muc NenGiaiNen sau khi cai. Neu di chuyen, chay lai file nay.'
