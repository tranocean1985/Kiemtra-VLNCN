@echo off
setlocal
title Phan mem thi VLNCN - Che do chay thu (cua so)

set "HTML=%~dp0PhanMemThi_VLNCN.html"

if not exist "%HTML%" (
  echo Khong tim thay file PhanMemThi_VLNCN.html trong thu muc nay.
  pause
  exit /b 1
)

set "BROWSER="
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set "BROWSER=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" set "BROWSER=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if not defined BROWSER (
  if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "BROWSER=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
  if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "BROWSER=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
)

if not defined BROWSER (
  echo Khong tim thay Edge hoac Chrome. Hay mo truc tiep file .html.
  pause
  exit /b 1
)

rem === Che do APP: cua so rieng giong phan mem, khong co thanh dia chi ===
start "" "%BROWSER%" --app="file:///%HTML%" --no-first-run --window-size=1100,800

exit /b 0
x
