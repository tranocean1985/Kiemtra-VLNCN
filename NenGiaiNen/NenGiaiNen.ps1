# =====================================================================
#  PHAN MEM NEN & GIAI NEN (ZIP / RAR / 7Z / TAR...)
#  - Mien phi, khong can cai dat, chay bang PowerShell co san trong Windows.
#  - Nen: tao file .ZIP (mo duoc tren moi may, khong can phan mem them).
#  - Giai nen: .ZIP (san co); .RAR/.7Z/.TAR/.GZ... (dung 7-Zip neu co,
#    neu khong thi dung tar.exe co san cua Windows 10/11).
# =====================================================================
param(
    [string]$CheDo = '',
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$DuongDan = @()
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()

$TieuDe = 'Nén & Giải nén'
$DuoiNen = @('.zip', '.rar', '.7z', '.tar', '.gz', '.tgz', '.bz2', '.tbz2', '.xz', '.txz', '.cab', '.iso')

# Xu ly tham so dong lenh (menu chuot phai "Send to" hoac keo tha vao file .bat)
$script:TuDong = ''
$dsBanDau = New-Object System.Collections.Generic.List[string]
if ($CheDo -eq 'Nen' -or $CheDo -eq 'GiaiNen') {
    $script:TuDong = $CheDo
} elseif ($CheDo -ne '') {
    $dsBanDau.Add($CheDo)
}
foreach ($d in $DuongDan) { if ($d) { $dsBanDau.Add($d) } }

# ---------------------------------------------------------------------
#  HAM TIEN ICH
# ---------------------------------------------------------------------
function Lay-DuongDanMoi([string]$path, [bool]$laThuMuc) {
    # Tra ve duong dan chua ton tai: "abc.zip" -> "abc (1).zip"...
    if (-not (Test-Path -LiteralPath $path)) { return $path }
    $cha = [IO.Path]::GetDirectoryName($path)
    if ($laThuMuc) {
        $ten = [IO.Path]::GetFileName($path); $duoi = ''
    } else {
        $ten = [IO.Path]::GetFileNameWithoutExtension($path); $duoi = [IO.Path]::GetExtension($path)
    }
    for ($i = 1; ; $i++) {
        $p = Join-Path $cha ('{0} ({1}){2}' -f $ten, $i, $duoi)
        if (-not (Test-Path -LiteralPath $p)) { return $p }
    }
}

function La-FileNen([string]$p) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $false }
    return ($DuoiNen -contains ([IO.Path]::GetExtension($p).ToLower()))
}

function Ten-KhongDuoi([string]$tep) {
    # "abc.tar.gz" -> "abc"
    $ten = [IO.Path]::GetFileNameWithoutExtension($tep)
    if ($ten.ToLower().EndsWith('.tar')) { $ten = $ten.Substring(0, $ten.Length - 4) }
    if (-not $ten) { $ten = 'GiaiNen' }
    return $ten
}

function Tim-Tep([string[]]$ds) {
    foreach ($p in $ds) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { return $p } }
    return $null
}

function Tim-7z {
    $ds = @()
    if ($PSScriptRoot) { $ds += (Join-Path $PSScriptRoot '7z.exe'); $ds += (Join-Path $PSScriptRoot '7za.exe') }
    foreach ($g in @($env:ProgramW6432, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($g) { $ds += (Join-Path $g '7-Zip\7z.exe') }
    }
    $p = Tim-Tep $ds
    if ($p) { return $p }
    $c = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    return $null
}

function Tim-UnRAR {
    $ds = @()
    if ($PSScriptRoot) { $ds += (Join-Path $PSScriptRoot 'UnRAR.exe') }
    foreach ($g in @($env:ProgramW6432, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($g) { $ds += (Join-Path $g 'WinRAR\UnRAR.exe') }
    }
    return (Tim-Tep $ds)
}

function Tim-Tar {
    return (Tim-Tep @((Join-Path $env:SystemRoot 'Sysnative\tar.exe'), (Join-Path $env:SystemRoot 'System32\tar.exe')))
}

function Q([string]$p) {
    # Bao duong dan trong dau ngoac kep an toan cho dong lenh
    if ($p.EndsWith('\')) { $p = $p + '.' }
    return '"' + $p + '"'
}

function Chay-Lenh([string]$exe, [string]$thamSo) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $thamSo
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardInput = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $o = $p.StandardOutput.ReadToEndAsync()
    $e = $p.StandardError.ReadToEndAsync()
    while (-not $p.HasExited) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }
    $p.WaitForExit()
    return [pscustomobject]@{ MaThoat = $p.ExitCode; NoiDung = ($o.Result + "`n" + $e.Result) }
}

function Giai-CoMatKhau([scriptblock]$lenh, [int]$maToiDa) {
    # Chay lenh giai nen; neu file co mat khau thi hoi nguoi dung (toi da 3 lan)
    $mk = ''
    for ($lan = 0; $lan -lt 4; $lan++) {
        $kq = & $lenh $mk
        if ($kq.MaThoat -le $maToiDa) { return }
        if ($kq.NoiDung -match '(?i)password|encrypted') {
            $thongBao = 'File được đặt mật khẩu. Nhập mật khẩu:'
            if ($mk) { $thongBao = 'Mật khẩu chưa đúng. Nhập lại mật khẩu:' }
            if ($lan -ge 3) { break }
            $mk = [Microsoft.VisualBasic.Interaction]::InputBox($thongBao, 'Mật khẩu', '')
            if ([string]::IsNullOrEmpty($mk)) { throw 'Đã hủy (chưa nhập mật khẩu).' }
            $mk = $mk.Replace('"', '\"')
            continue
        }
        $nd = $kq.NoiDung.Trim()
        if ($nd.Length -gt 600) { $nd = '...' + $nd.Substring($nd.Length - 600) }
        throw ("Lỗi giải nén (mã {0}):`n{1}" -f $kq.MaThoat, $nd)
    }
    throw 'Sai mật khẩu.'
}

# ---------------------------------------------------------------------
#  NEN ZIP
# ---------------------------------------------------------------------
function Nen-Zip([object[]]$items, [string]$zipPath, [scriptblock]$tienDo) {
    $zipFull = [IO.Path]::GetFullPath($zipPath)
    $ds = New-Object System.Collections.Generic.List[object]   # @(duong dan that, ten trong zip); duong dan $null = thu muc rong

    foreach ($it in $items) {
        $it = [string]$it
        if (Test-Path -LiteralPath $it -PathType Container) {
            $goc = (Get-Item -LiteralPath $it -Force).FullName.TrimEnd('\')
            $cha = [IO.Path]::GetDirectoryName($goc)
            if (-not $cha) { $cha = $goc }
            $catBo = $cha.TrimEnd('\').Length + 1
            $ten = { param($f) $f.Substring($catBo).Replace('\', '/') }
            $ds.Add(@($null, ((& $ten $goc) + '/')))
            foreach ($f in (Get-ChildItem -LiteralPath $goc -Recurse -Force -ErrorAction SilentlyContinue)) {
                if ($f.PSIsContainer) {
                    $ds.Add(@($null, ((& $ten $f.FullName) + '/')))
                } elseif ($f.FullName -ne $zipFull) {
                    $ds.Add(@($f.FullName, (& $ten $f.FullName)))
                }
            }
        } elseif (Test-Path -LiteralPath $it -PathType Leaf) {
            $f = Get-Item -LiteralPath $it -Force
            if ($f.FullName -ne $zipFull) { $ds.Add(@($f.FullName, $f.Name)) }
        }
    }
    if ($ds.Count -eq 0) { throw 'Không có file nào để nén.' }

    $boQua = New-Object System.Collections.Generic.List[string]
    $fs = [IO.File]::Open($zipFull, [IO.FileMode]::CreateNew)
    try {
        $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create, $false, [Text.Encoding]::UTF8)
        try {
            $n = $ds.Count
            for ($i = 0; $i -lt $n; $i++) {
                $muc = $ds[$i]
                if ($null -eq $muc[0]) {
                    $zip.CreateEntry($muc[1]) | Out-Null
                } else {
                    try {
                        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $muc[0], $muc[1], [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
                    } catch {
                        $boQua.Add($muc[0])
                    }
                }
                if (($i % 10 -eq 0) -or ($i -eq $n - 1)) { & $tienDo ($i + 1) $n $muc[1] }
            }
        } finally { $zip.Dispose() }
    } finally { $fs.Dispose() }
    return ,$boQua
}

# ---------------------------------------------------------------------
#  GIAI NEN
# ---------------------------------------------------------------------
function Giai-Zip([string]$tep, [string]$dich, [scriptblock]$tienDo) {
    $dichFull = [IO.Path]::GetFullPath($dich).TrimEnd('\') + '\'
    $zip = [System.IO.Compression.ZipFile]::OpenRead($tep)
    try {
        $n = $zip.Entries.Count
        $i = 0
        foreach ($e in $zip.Entries) {
            $i++
            try { $dau = [IO.Path]::GetFullPath([IO.Path]::Combine($dichFull, $e.FullName)) }
            catch { continue }   # ten file khong hop le -> bo qua
            if (-not $dau.StartsWith($dichFull, [StringComparison]::OrdinalIgnoreCase)) { continue }   # chong file doc hai (../)
            if ($e.FullName.EndsWith('/') -or $e.FullName.EndsWith('\')) {
                [IO.Directory]::CreateDirectory($dau) | Out-Null
            } else {
                [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dau)) | Out-Null
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dau, $true)
            }
            if (($i % 10 -eq 0) -or ($i -eq $n)) { & $tienDo $i $n $e.FullName }
        }
    } finally { $zip.Dispose() }
}

function Giai-Nen([string]$tep, [string]$dich, [scriptblock]$tienDo) {
    $duoi = [IO.Path]::GetExtension($tep).ToLower()
    [IO.Directory]::CreateDirectory($dich) | Out-Null
    $dich = $dich.TrimEnd('\')
    $sz = Tim-7z

    if ($duoi -eq '.zip') {
        try { Giai-Zip $tep $dich $tienDo; return }
        catch {
            if (-not $sz) {
                throw ("Không giải nén được file ZIP này: {0}`n`n(Nếu file ZIP có mật khẩu, hãy cài 7-Zip miễn phí tại 7-zip.org rồi thử lại.)" -f $_.Exception.Message)
            }
        }
    }

    & $tienDo -1 0 ([IO.Path]::GetFileName($tep))
    if ($sz) {
        Giai-CoMatKhau { param($mk) Chay-Lenh $sz ('x -y -bd -p"{0}" -o{1} {2}' -f $mk, (Q $dich), (Q $tep)) } 1
        return
    }
    if ($duoi -eq '.rar') {
        $ur = Tim-UnRAR
        if ($ur) {
            Giai-CoMatKhau {
                param($mk)
                $p = '-p-'; if ($mk) { $p = '-p"' + $mk + '"' }
                Chay-Lenh $ur ('x -y -idq {0} {1} "{2}\\"' -f $p, (Q $tep), $dich)
            } 1
            return
        }
    }
    $tar = Tim-Tar
    if ($tar) {
        $kq = Chay-Lenh $tar ('-xf {0} -C {1}' -f (Q $tep), (Q $dich))
        if ($kq.MaThoat -eq 0) { return }
        $nd = $kq.NoiDung.Trim()
        if ($nd.Length -gt 400) { $nd = $nd.Substring(0, 400) + '...' }
        throw ("Windows chưa hỗ trợ giải nén file này (hoặc file có mật khẩu/bị lỗi).`n{0}`n`nCách khắc phục: cài 7-Zip MIỄN PHÍ tại 7-zip.org, phần mềm sẽ tự dùng 7-Zip để giải nén mọi loại file RAR/7Z." -f $nd)
    }
    throw 'Không tìm thấy công cụ giải nén loại file này. Hãy cài 7-Zip MIỄN PHÍ tại 7-zip.org rồi thử lại.'
}

# ---------------------------------------------------------------------
#  GIAO DIEN
# ---------------------------------------------------------------------
$fontThuong = New-Object System.Drawing.Font('Segoe UI', 10)
$fontDam = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)

$form = New-Object System.Windows.Forms.Form
$form.Text = $TieuDe
$form.Size = New-Object System.Drawing.Size(660, 540)
$form.MinimumSize = New-Object System.Drawing.Size(560, 460)
$form.StartPosition = 'CenterScreen'
$form.Font = $fontThuong
$form.AllowDrop = $true
try { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Join-Path $env:SystemRoot 'explorer.exe')) } catch { }

$lblHD = New-Object System.Windows.Forms.Label
$lblHD.Text = 'Kéo thả file / thư mục vào ô bên dưới (hoặc bấm nút Thêm), rồi chọn NÉN hoặc GIẢI NÉN.'
$lblHD.Location = New-Object System.Drawing.Point(12, 10)
$lblHD.Size = New-Object System.Drawing.Size(620, 22)
$lblHD.Anchor = 'Top, Left, Right'
$form.Controls.Add($lblHD)

$lst = New-Object System.Windows.Forms.ListBox
$lst.Location = New-Object System.Drawing.Point(12, 36)
$lst.Size = New-Object System.Drawing.Size(470, 300)
$lst.Anchor = 'Top, Bottom, Left, Right'
$lst.SelectionMode = 'MultiExtended'
$lst.HorizontalScrollbar = $true
$lst.IntegralHeight = $false
$lst.AllowDrop = $true
$form.Controls.Add($lst)

function Tao-Nut([string]$chu, [int]$x, [int]$y, [int]$rong, [int]$cao) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $chu
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($rong, $cao)
    $b.Anchor = 'Top, Right'
    $form.Controls.Add($b)
    return $b
}

$btnThemFile   = Tao-Nut 'Thêm file...'     492 36  140 34
$btnThemThuMuc = Tao-Nut 'Thêm thư mục...'  492 76  140 34
$btnXoaChon    = Tao-Nut 'Bỏ mục đã chọn'   492 116 140 34
$btnXoaHet     = Tao-Nut 'Xóa danh sách'    492 156 140 34

$btnNen = Tao-Nut 'NÉN thành ZIP' 492 220 140 50
$btnNen.Font = $fontDam
$btnNen.BackColor = [System.Drawing.Color]::FromArgb(220, 240, 220)

$btnGiai = Tao-Nut 'GIẢI NÉN' 492 280 140 50
$btnGiai.Font = $fontDam
$btnGiai.BackColor = [System.Drawing.Color]::FromArgb(215, 230, 250)

$chkNoiKhac = New-Object System.Windows.Forms.CheckBox
$chkNoiKhac.Text = 'Tự chọn nơi lưu kết quả (mặc định: cùng thư mục với file gốc)'
$chkNoiKhac.Location = New-Object System.Drawing.Point(12, 344)
$chkNoiKhac.Size = New-Object System.Drawing.Size(620, 24)
$chkNoiKhac.Anchor = 'Bottom, Left, Right'
$form.Controls.Add($chkNoiKhac)

$chkMo = New-Object System.Windows.Forms.CheckBox
$chkMo.Text = 'Mở thư mục kết quả khi xong'
$chkMo.Checked = $true
$chkMo.Location = New-Object System.Drawing.Point(12, 370)
$chkMo.Size = New-Object System.Drawing.Size(620, 24)
$chkMo.Anchor = 'Bottom, Left, Right'
$form.Controls.Add($chkMo)

$pb = New-Object System.Windows.Forms.ProgressBar
$pb.Location = New-Object System.Drawing.Point(12, 402)
$pb.Size = New-Object System.Drawing.Size(620, 22)
$pb.Anchor = 'Bottom, Left, Right'
$form.Controls.Add($pb)

$lblTT = New-Object System.Windows.Forms.Label
$lblTT.Text = 'Sẵn sàng.'
$lblTT.Location = New-Object System.Drawing.Point(12, 430)
$lblTT.Size = New-Object System.Drawing.Size(620, 44)
$lblTT.Anchor = 'Bottom, Left, Right'
$lblTT.AutoEllipsis = $true
$form.Controls.Add($lblTT)

# ---------------------------------------------------------------------
#  XU LY SU KIEN
# ---------------------------------------------------------------------
function Them-Muc([string[]]$ds) {
    foreach ($p in $ds) {
        if (-not $p) { continue }
        if (-not (Test-Path -LiteralPath $p)) { continue }
        $full = (Get-Item -LiteralPath $p -Force).FullName
        if (-not $lst.Items.Contains($full)) { [void]$lst.Items.Add($full) }
    }
    $lblTT.Text = ('Danh sách: {0} mục.' -f $lst.Items.Count)
}

function Thong-Bao([string]$nd, [string]$loai) {
    $icon = [System.Windows.Forms.MessageBoxIcon]::Information
    if ($loai -eq 'loi') { $icon = [System.Windows.Forms.MessageBoxIcon]::Error }
    if ($loai -eq 'canh') { $icon = [System.Windows.Forms.MessageBoxIcon]::Warning }
    [void][System.Windows.Forms.MessageBox]::Show($form, $nd, $TieuDe, [System.Windows.Forms.MessageBoxButtons]::OK, $icon)
}

function Khoa-GiaoDien([bool]$khoa) {
    foreach ($c in @($btnThemFile, $btnThemThuMuc, $btnXoaChon, $btnXoaHet, $btnNen, $btnGiai, $lst, $chkNoiKhac)) { $c.Enabled = -not $khoa }
    if ($khoa) { $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor } else { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
}

$script:TienTo = ''
$tienDo = {
    param($i, $n, $ten)
    if ($i -lt 0) {
        $pb.Style = 'Marquee'
        $lblTT.Text = $script:TienTo + 'Đang giải nén: ' + $ten
    } else {
        $pb.Style = 'Blocks'
        $pb.Maximum = [Math]::Max(1, $n)
        $pb.Value = [Math]::Min([Math]::Max(0, $i), $pb.Maximum)
        $lblTT.Text = ('{0}{1}/{2}: {3}' -f $script:TienTo, $i, $n, $ten)
    }
    [System.Windows.Forms.Application]::DoEvents()
}

function Mo-ThuMuc([string]$p, [bool]$chonFile) {
    if (-not $chkMo.Checked) { return }
    try {
        if ($chonFile) { Start-Process explorer.exe ('/select,"{0}"' -f $p) }
        else { Start-Process explorer.exe ('"{0}"' -f $p) }
    } catch { }
}

$xuLyKeoTha = {
    param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    } else {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::None
    }
}
$xuLyTha = {
    param($s, $e)
    $ds = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($ds) { Them-Muc $ds }
}
$form.Add_DragEnter($xuLyKeoTha); $form.Add_DragDrop($xuLyTha)
$lst.Add_DragEnter($xuLyKeoTha);  $lst.Add_DragDrop($xuLyTha)

$btnThemFile.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Multiselect = $true
    $dlg.Title = 'Chọn file'
    $dlg.Filter = 'Tất cả file (*.*)|*.*|File nén (zip, rar, 7z...)|*.zip;*.rar;*.7z;*.tar;*.gz;*.tgz;*.bz2;*.xz;*.cab;*.iso'
    if ($dlg.ShowDialog($form) -eq 'OK') { Them-Muc $dlg.FileNames }
})

$btnThemThuMuc.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Chọn thư mục cần nén'
    if ($dlg.ShowDialog($form) -eq 'OK') { Them-Muc @($dlg.SelectedPath) }
})

$btnXoaChon.Add_Click({
    $chon = @($lst.SelectedItems)
    foreach ($c in $chon) { $lst.Items.Remove($c) }
    $lblTT.Text = ('Danh sách: {0} mục.' -f $lst.Items.Count)
})
$lst.Add_KeyDown({ param($s, $e) if ($e.KeyCode -eq 'Delete') { $btnXoaChon.PerformClick() } })

$btnXoaHet.Add_Click({ $lst.Items.Clear(); $lblTT.Text = 'Sẵn sàng.'; $pb.Value = 0 })

# ---------- NUT NEN ----------
$btnNen.Add_Click({
    $items = @($lst.Items | ForEach-Object { [string]$_ })
    if ($items.Count -eq 0) { Thong-Bao 'Chưa có file / thư mục nào. Hãy kéo thả hoặc bấm "Thêm".' 'canh'; return }

    # Goi y ten file zip
    $dau = $items[0].TrimEnd('\')
    $chaMacDinh = [IO.Path]::GetDirectoryName($dau)
    if (-not $chaMacDinh) { $chaMacDinh = $dau }
    if ($items.Count -eq 1) {
        if (Test-Path -LiteralPath $dau -PathType Container) { $tenGoiY = [IO.Path]::GetFileName($dau) }
        else { $tenGoiY = [IO.Path]::GetFileNameWithoutExtension($dau) }
    } else {
        $tenGoiY = [IO.Path]::GetFileName($chaMacDinh.TrimEnd('\'))
    }
    if (-not $tenGoiY) { $tenGoiY = 'NenFile' }
    $zipPath = Lay-DuongDanMoi (Join-Path $chaMacDinh ($tenGoiY + '.zip')) $false

    if ($chkNoiKhac.Checked) {
        $dlg = New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Title = 'Lưu file ZIP'
        $dlg.Filter = 'File ZIP (*.zip)|*.zip'
        $dlg.InitialDirectory = $chaMacDinh
        $dlg.FileName = [IO.Path]::GetFileName($zipPath)
        $dlg.OverwritePrompt = $true
        if ($dlg.ShowDialog($form) -ne 'OK') { return }
        $zipPath = $dlg.FileName
        if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    }

    Khoa-GiaoDien $true
    $script:TienTo = 'Đang nén '
    try {
        $boQua = Nen-Zip $items $zipPath $tienDo
        $kb = [Math]::Round((Get-Item -LiteralPath $zipPath).Length / 1KB, 1)
        $lblTT.Text = ('Đã nén xong: {0} ({1} KB)' -f $zipPath, $kb)
        $nd = "Đã nén xong!`n`n$zipPath`nDung lượng: $kb KB"
        if ($boQua.Count -gt 0) {
            $nd += "`n`nCó {0} file không đọc được (đang mở hoặc bị khóa) nên bỏ qua:`n{1}" -f $boQua.Count, (($boQua | Select-Object -First 10) -join "`n")
            Thong-Bao $nd 'canh'
        } elseif ($script:TuDong -eq '') {
            Thong-Bao $nd 'tt'
        }
        Mo-ThuMuc $zipPath $true
    } catch {
        try { if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force } } catch { }
        $lblTT.Text = 'Nén thất bại.'
        Thong-Bao ('Nén thất bại: ' + $_.Exception.Message) 'loi'
    } finally {
        $pb.Style = 'Blocks'
        Khoa-GiaoDien $false
    }
})

# ---------- NUT GIAI NEN ----------
$btnGiai.Add_Click({
    $items = @($lst.Items | ForEach-Object { [string]$_ })
    $dsNen = @($items | Where-Object { La-FileNen $_ })
    if ($dsNen.Count -eq 0) {
        Thong-Bao ("Danh sách chưa có file nén nào.`nCác loại hỗ trợ: " + ($DuoiNen -join ', ')) 'canh'
        return
    }

    $noiChung = $null
    if ($chkNoiKhac.Checked) {
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Chọn thư mục để giải nén vào'
        if ($dlg.ShowDialog($form) -ne 'OK') { return }
        $noiChung = $dlg.SelectedPath
    }

    Khoa-GiaoDien $true
    $thanhCong = New-Object System.Collections.Generic.List[string]
    $loi = New-Object System.Collections.Generic.List[string]
    $k = 0
    foreach ($tep in $dsNen) {
        $k++
        $script:TienTo = ''
        if ($dsNen.Count -gt 1) { $script:TienTo = ('[File {0}/{1}] ' -f $k, $dsNen.Count) }
        $cha = $noiChung
        if (-not $cha) { $cha = [IO.Path]::GetDirectoryName($tep) }
        $dich = Lay-DuongDanMoi (Join-Path $cha (Ten-KhongDuoi $tep)) $true
        try {
            Giai-Nen $tep $dich $tienDo
            $thanhCong.Add($dich)
        } catch {
            $loi.Add(([IO.Path]::GetFileName($tep) + ': ' + $_.Exception.Message))
            # Xoa thu muc rong neu giai nen that bai
            try {
                if ((Test-Path -LiteralPath $dich) -and -not (Get-ChildItem -LiteralPath $dich -Force | Select-Object -First 1)) {
                    Remove-Item -LiteralPath $dich -Force
                }
            } catch { }
        }
    }
    $pb.Style = 'Blocks'
    Khoa-GiaoDien $false

    $lblTT.Text = ('Giải nén xong: {0} thành công, {1} lỗi.' -f $thanhCong.Count, $loi.Count)
    if ($loi.Count -gt 0) {
        Thong-Bao (("Giải nén: {0} thành công, {1} lỗi.`n`n" -f $thanhCong.Count, $loi.Count) + ($loi -join "`n`n")) 'loi'
    } elseif ($script:TuDong -eq '') {
        Thong-Bao ("Đã giải nén xong!`n`n" + ($thanhCong -join "`n")) 'tt'
    }
    if ($thanhCong.Count -eq 1) { Mo-ThuMuc $thanhCong[0] $false }
    elseif ($thanhCong.Count -gt 1) { Mo-ThuMuc ([IO.Path]::GetDirectoryName($thanhCong[0])) $false }
})

# ---------------------------------------------------------------------
#  KHOI DONG
# ---------------------------------------------------------------------
if ($dsBanDau.Count -gt 0) { Them-Muc $dsBanDau.ToArray() }

$form.Add_Shown({
    $form.Activate()
    if ($script:TuDong -eq 'Nen') { $btnNen.PerformClick(); $form.Close() }
    elseif ($script:TuDong -eq 'GiaiNen') { $btnGiai.PerformClick(); $form.Close() }
})

[void]$form.ShowDialog()
