@echo off
setlocal

rem CreateAIAgentInstructionFiles.bat
rem Version: 0.5.0
rem Creates native AI instruction files and synchronizes the canonical Geurts documentation.
rem Safe to run multiple times. Existing project-specific instruction files are not overwritten.

set "GEURTS_AGENT_SETUP_VERSION=0.5.0"
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
if errorlevel 1 exit /b 1

call :CopyIfMissing "%TEMPLATE_DIR%\copilot-instructions.md" "%PROJECT_ROOT%\.github\copilot-instructions.md" ".github\copilot-instructions.md"
if errorlevel 1 exit /b 1

call :CopyIfMissing "%TEMPLATE_DIR%\instructions\geurts-unity.instructions.md" "%PROJECT_ROOT%\.github\instructions\geurts-unity.instructions.md" ".github\instructions\geurts-unity.instructions.md"
if errorlevel 1 exit /b 1

call :CopyIfMissing "%TEMPLATE_DIR%\instructions\geurts-game-design.instructions.md" "%PROJECT_ROOT%\.github\instructions\geurts-game-design.instructions.md" ".github\instructions\geurts-game-design.instructions.md"
if errorlevel 1 exit /b 1

if not exist "%SCRIPT_DIR%BootstrapGeurtsInstructions.ps1" (
    echo ERROR: Missing Tools\BootstrapGeurtsInstructions.ps1
    exit /b 1
)

if not exist "%SCRIPT_DIR%GeurtsRepository.json" (
    echo ERROR: Missing Tools\GeurtsRepository.json
    exit /b 1
)

echo.
echo Synchronizing canonical Geurts documentation before Codex work...
pushd "%PROJECT_ROOT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "Tools\BootstrapGeurtsInstructions.ps1"
set "BOOTSTRAP_EXIT=%ERRORLEVEL%"
popd

if not "%BOOTSTRAP_EXIT%"=="0" (
    echo.
    echo ERROR: Geurts documentation synchronization failed.
    echo Codex should not modify project files until this is resolved.
    exit /b %BOOTSTRAP_EXIT%
)

echo.
echo AI agent setup complete. SYNC OK.
echo Codex should read AGENTS.md, then .geurts\upstream\AI_READ_FIRST.md.
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
