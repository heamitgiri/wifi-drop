@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   WiFi Drop - Windows 11 Release Build ^& Packager
echo ========================================================

where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter is not found in PATH.
    echo Please install Flutter and Visual Studio 2022 C++ desktop tools.
    exit /b 1
)

echo [1/6] Running Flutter Doctor...
call flutter doctor -v
if %ERRORLEVEL% neq 0 (
    echo [WARNING] Flutter doctor reported issues. Proceeding with caution.
)

echo [2/6] Fetching dependencies...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] flutter pub get failed.
    exit /b 1
)

echo [3/6] Running Unit and Widget Tests...
call flutter test
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Tests failed. Aborting build.
    exit /b 1
)

echo [4/6] Compiling Native Windows Release Executable...
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Windows build failed.
    exit /b 1
)

set RELEASE_DIR=build\windows\x64\runner\Release
if not exist "%RELEASE_DIR%\WiFiDrop.exe" (
    echo [ERROR] Compiled binary not found at %RELEASE_DIR%\WiFiDrop.exe
    exit /b 1
)

echo [5/6] Packaging Release Bundle to WiFiDrop-Windows-x64.zip...
if exist "WiFiDrop-Windows-x64.zip" del /f /q "WiFiDrop-Windows-x64.zip"

powershell -Command "Compress-Archive -Path '%RELEASE_DIR%\*' -DestinationPath 'WiFiDrop-Windows-x64.zip' -Force"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to create ZIP archive.
    exit /b 1
)

echo [6/6] Computing SHA-256 Checksum...
powershell -Command "Get-FileHash -Algorithm SHA256 'WiFiDrop-Windows-x64.zip' | Format-List"

echo ========================================================
echo   BUILD SUCCESSFUL!
echo   Package: WiFiDrop-Windows-x64.zip
echo ========================================================
