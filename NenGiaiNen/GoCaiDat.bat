@echo off
rem Xoa cac loi tat da tao (Desktop va Send to)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[Environment]::GetFolderPath('SendTo'); $d=[Environment]::GetFolderPath('Desktop'); Get-ChildItem -LiteralPath $s,$d -Filter '*.lnk' | Where-Object { $_.Name -like 'N*n*ZIP.lnk' -or $_.Name -like 'Gi*i n*n t*i *.lnk' -or $_.Name -like 'N*n - Gi*i n*n*.lnk' } | Remove-Item -Force; Write-Host 'Da go cac loi tat.'"
pause
