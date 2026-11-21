@echo off
setlocal
title WiFi Drop - Local Peer-to-Peer File Sharing

echo ========================================================
echo   Starting WiFi Drop on Windows 11
echo ========================================================

where py >nul 2>&1
if %ERRORLEVEL% equ 0 (
    start "" http://127.0.0.1:8765
    py -3 p2p_engine.py --name "%COMPUTERNAME%" --type laptop --port 8765
    goto :end
)

where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    start "" http://127.0.0.1:8765
    python p2p_engine.py --name "%COMPUTERNAME%" --type laptop --port 8765
    goto :end
)

echo [ERROR] Python 3 is required for the portable release launcher.
echo Please install Python from https://python.org (check "Add Python to PATH")
echo or build the standalone native C++ Flutter .exe using scripts\build_windows.bat
pause

:end
