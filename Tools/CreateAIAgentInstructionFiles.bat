@echo off
setlocal

rem CreateAIAgentInstructionFiles.bat
rem Version: 0.9.0
rem Compatibility launcher for safe native-entry setup. GDD scaffolding and manifest maintenance are separately explicit.

set "SCRIPT_DIR=%~dp0"
if not exist "%SCRIPT_DIR%ManageGeurtsAgentInstructions.ps1" (
    echo ERROR: Missing Tools\ManageGeurtsAgentInstructions.ps1
    exit /b 1
)

if /I not "%~1"=="-ProjectRoot" (
    echo ERROR: Usage: CreateAIAgentInstructionFiles.bat -ProjectRoot ^<UnityProjectRoot^> [-IncludeGameDesignScaffolding] [-UpdateGameDesignManifest] [options]
    exit /b 1
)
if "%~2"=="" (
    echo ERROR: -ProjectRoot requires a Unity project path.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%ManageGeurtsAgentInstructions.ps1" %*
exit /b %ERRORLEVEL%
