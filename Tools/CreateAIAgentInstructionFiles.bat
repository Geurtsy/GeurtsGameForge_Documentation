@echo off
setlocal

rem CreateAIAgentInstructionFiles.bat
rem Version: 0.4.0
rem Creates native AI instruction files for GitHub Copilot, Codex, and compatible agents.
rem Safe to run multiple times. This script creates missing files only.
rem It does not delete, move, overwrite, or rename existing files.

set "GEURTS_AGENT_SETUP_VERSION=0.4.0"
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%.") do set "SCRIPT_FOLDER=%%~nxI"

if /I not "%SCRIPT_FOLDER%"=="Tools" (
    echo ERROR: This batch file must be located inside ProjectRoot\Tools.
    echo Current script folder: %SCRIPT_FOLDER%
    exit /b 1
)

for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_ROOT=%%~fI"
set "TEMPLATE_DIR=%SCRIPT_DIR%AIAgentInstructionTemplates"

if not exist "%TEMPLATE_DIR%" (
    echo ERROR: Template folder missing.
    echo Expected: %TEMPLATE_DIR%
    exit /b 1
)

echo.
echo Creating Geurts Game Forge AI agent instruction files...
echo Script version: %GEURTS_AGENT_SETUP_VERSION%
echo Project root: %PROJECT_ROOT%
echo.

call :CopyIfMissing "%TEMPLATE_DIR%\AGENTS.md" "%PROJECT_ROOT%\AGENTS.md" "AGENTS.md"
call :CopyIfMissing "%TEMPLATE_DIR%\copilot-instructions.md" "%PROJECT_ROOT%\.github\copilot-instructions.md" ".github\copilot-instructions.md"
call :CopyIfMissing "%TEMPLATE_DIR%\instructions\geurts-unity.instructions.md" "%PROJECT_ROOT%\.github\instructions\geurts-unity.instructions.md" ".github\instructions\geurts-unity.instructions.md"
call :CopyIfMissing "%TEMPLATE_DIR%\instructions\geurts-game-design.instructions.md" "%PROJECT_ROOT%\.github\instructions\geurts-game-design.instructions.md" ".github\instructions\geurts-game-design.instructions.md"
call :CopyIfMissing "%TEMPLATE_DIR%\GameDesign\README.md" "%PROJECT_ROOT%\Docs\GameDesign\README.md" "Docs\GameDesign\README.md"
call :CopyIfMissing "%TEMPLATE_DIR%\GameDesign\GameDesignManifest.md" "%PROJECT_ROOT%\Docs\GameDesign\GameDesignManifest.md" "Docs\GameDesign\GameDesignManifest.md"

echo.
echo AI agent instruction file creation complete.
echo.
exit /b 0

:CopyIfMissing
set "SOURCE_FILE=%~1"
set "TARGET_FILE=%~2"
set "DISPLAY_PATH=%~3"

if not exist "%SOURCE_FILE%" (
    echo Missing template: %SOURCE_FILE%
    exit /b 1
)

if exist "%TARGET_FILE%" (
    echo Exists:  %DISPLAY_PATH%
    exit /b 0
)

for %%I in ("%TARGET_FILE%") do set "TARGET_DIR=%%~dpI"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
copy /Y "%SOURCE_FILE%" "%TARGET_FILE%" >nul
if errorlevel 1 (
    echo Failed:  %DISPLAY_PATH%
    exit /b 1
)

echo Created: %DISPLAY_PATH%
exit /b 0
