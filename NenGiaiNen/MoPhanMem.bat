@echo off
rem Mo phan mem Nen & Giai nen. Co the keo tha file/thu muc vao file .bat nay.
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0NenGiaiNen.ps1" %*
