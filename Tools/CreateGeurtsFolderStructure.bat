@echo off
setlocal

rem CreateGeurtsFolderStructure.bat
rem Version: 0.7.0
rem Compatibility launcher for the definition-driven PowerShell utility.

set "SCRIPT_DIR=%~dp0"
if not exist "%SCRIPT_DIR%CreateGeurtsFolderStructure.ps1" (
    echo ERROR: Missing Tools\CreateGeurtsFolderStructure.ps1
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%CreateGeurtsFolderStructure.ps1" %*
exit /b %ERRORLEVEL%
