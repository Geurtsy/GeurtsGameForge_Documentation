@echo off
setlocal

rem CreateAIAgentInstructionFiles.bat
rem Version: 0.7.0
rem Compatibility launcher for the safe PowerShell project setup utility.

set "SCRIPT_DIR=%~dp0"
if not exist "%SCRIPT_DIR%ManageGeurtsAgentInstructions.ps1" (
    echo ERROR: Missing Tools\ManageGeurtsAgentInstructions.ps1
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%ManageGeurtsAgentInstructions.ps1" %*
exit /b %ERRORLEVEL%
