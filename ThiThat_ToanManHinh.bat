@echo off
setlocal
title Phan mem thi VLNCN - Che do thi that (toan man hinh)

rem === Duong dan file thi (cung thu muc voi file .bat nay) ===
set "HTML=%~dp0PhanMemThi_VLNCN.html"

if not exist "%HTML%" (
  echo Khong tim thay file PhanMemThi_VLNCN.html trong thu muc nay.
  echo Hay de file .bat va file .html trong cung mot thu muc.
  pause
  exit /b 1
)

rem === Tim Microsoft Edge (co san tren moi may Windows 10/11) ===
set "BROWSER="
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "BROWSER=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "BROWSER=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"

rem === Neu khong co Edge thi tim Google Chrome ===
if not defined BROWSER (
  if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "BROWSER=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
  if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "BROWSER=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
)

if not defined BROWSER (
  echo Khong tim thay Microsoft Edge hoac Google Chrome.
  echo Van co the mo truc tiep file PhanMemThi_VLNCN.html bang trinh duyet.
  pause
  exit /b 1
)

rem === Chay che do KIOSK toan man hinh (khoa lai de thi) ===
start "" "%BROWSER%" --kiosk "file:///%HTML%" --edge-kiosk-type=fullscreen --no-first-run --disable-features=Translate

exit /b 0
