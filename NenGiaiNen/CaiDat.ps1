# Tao loi tat: Desktop + menu chuot phai "Send to" (Gui toi). Khong can quyen Admin.
$ErrorActionPreference = 'Stop'
$ps1   = Join-Path $PSScriptRoot 'NenGiaiNen.ps1'
$psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$icon  = (Join-Path $env:SystemRoot 'System32\zipfldr.dll') + ',0'
$sh    = New-Object -ComObject WScript.Shell
$sendTo  = [Environment]::GetFolderPath('SendTo')
$desktop = [Environment]::GetFolderPath('Desktop')

function Tao-LoiTat([string]$noiLuu, [string]$ten, [string]$cheDo) {
    # WScript.Shell khong ghi duoc ten co dau tieng Viet -> ghi ten tam (khong dau) roi doi ten
    $tam = Join-Path $noiLuu ('NenGiaiNen_tam_' + [guid]::NewGuid().ToString('N') + '.lnk')
    $dich = Join-Path $noiLuu ($ten + '.lnk')
    $lnk = $sh.CreateShortcut($tam)
    $lnk.TargetPath = $psExe
    $lnk.Arguments = ('-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "{0}" {1}' -f $ps1, $cheDo).Trim()
    $lnk.WorkingDirectory = $PSScriptRoot
    $lnk.IconLocation = $icon
    $lnk.WindowStyle = 7
    $lnk.Save()
    if (Test-Path -LiteralPath $dich) { Remove-Item -LiteralPath $dich -Force }
    [IO.File]::Move($tam, $dich)
}

Tao-LoiTat $sendTo  'Nén thành ZIP'     'Nen'
Tao-LoiTat $sendTo  'Giải nén tại đây'  'GiaiNen'
Tao-LoiTat $sendTo  'Nén - Giải nén (mở cửa sổ)' ''
Tao-LoiTat $desktop 'Nén - Giải nén'    ''

Write-Host ''
Write-Host 'DA CAI DAT XONG:'
Write-Host ' - Desktop: bieu tuong "Nen - Giai nen"'
Write-Host ' - Chuot phai vao file/thu muc > Send to (Gui toi) > "Nen thanh ZIP" / "Giai nen tai day"'
Write-Host ''
Write-Host 'Luu y: KHONG di chuyen thu muc NenGiaiNen sau khi cai. Neu di chuyen, chay lai file nay.'
