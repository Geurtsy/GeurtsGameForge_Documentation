@echo off
setlocal
set "GEURTS_FOLDER_STRUCTURE_VERSION=0.4.0"

rem CreateGeurtsFolderStructure.bat
rem Version: 0.4.0
rem Creates the Geurts Game Forge Unity project folder structure.
rem Safe to run multiple times. This script creates missing folders only.
rem It does not delete, move, overwrite, or rename existing files.

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%.") do set "SCRIPT_FOLDER=%%~nxI"

if /I not "%SCRIPT_FOLDER%"=="Tools" (
    echo ERROR: This batch file must be located inside ProjectRoot\Tools.
    echo Current script folder: %SCRIPT_FOLDER%
    exit /b 1
)

pushd "%SCRIPT_DIR%.."

if errorlevel 1 (
    echo Failed to locate project root.
    exit /b 1
)

echo.
echo Creating Geurts Game Forge folder structure...
echo Script version: %GEURTS_FOLDER_STRUCTURE_VERSION%
echo Project root: %CD%
echo.

call :MakeFolder "Assets"
call :MakeFolder "Packages"
call :MakeFolder "ProjectSettings"
call :MakeFolder "UserSettings"
call :MakeFolder "Docs"
call :MakeFolder "Docs\GameDesign"
call :MakeFolder "Builds"
call :MakeFolder "Tools"
call :MakeFolder "External"

call :MakeFolder "Assets\_Project"
call :MakeFolder "Assets\_ThirdParty"
call :MakeFolder "Assets\_Addressables"
call :MakeFolder "Assets\_Generated"
call :MakeFolder "Assets\Gizmos"

call :MakeFolder "Assets\_Project\Art"
call :MakeFolder "Assets\_Project\Art\2D"
call :MakeFolder "Assets\_Project\Art\3D"
call :MakeFolder "Assets\_Project\Art\Animations"
call :MakeFolder "Assets\_Project\Art\Sprites"
call :MakeFolder "Assets\_Project\Art\Textures"
call :MakeFolder "Assets\_Project\Art\Concept"

call :MakeFolder "Assets\_Project\Audio"
call :MakeFolder "Assets\_Project\Audio\Music"
call :MakeFolder "Assets\_Project\Audio\SFX"
call :MakeFolder "Assets\_Project\Audio\Ambience"
call :MakeFolder "Assets\_Project\Audio\Dialogue"
call :MakeFolder "Assets\_Project\Audio\Mixers"

call :MakeFolder "Assets\_Project\Data"
call :MakeFolder "Assets\_Project\Data\Items"
call :MakeFolder "Assets\_Project\Data\Enemies"
call :MakeFolder "Assets\_Project\Data\Weapons"
call :MakeFolder "Assets\_Project\Data\Progression"
call :MakeFolder "Assets\_Project\Data\Tuning"

call :MakeFolder "Assets\_Project\Materials"

call :MakeFolder "Assets\_Project\Prefabs"
call :MakeFolder "Assets\_Project\Prefabs\Characters"
call :MakeFolder "Assets\_Project\Prefabs\Environment"
call :MakeFolder "Assets\_Project\Prefabs\Props"
call :MakeFolder "Assets\_Project\Prefabs\UI"
call :MakeFolder "Assets\_Project\Prefabs\Weapons"
call :MakeFolder "Assets\_Project\Prefabs\Systems"

call :MakeFolder "Assets\_Project\Scenes"
call :MakeFolder "Assets\_Project\Scenes\Boot"
call :MakeFolder "Assets\_Project\Scenes\Frontend"
call :MakeFolder "Assets\_Project\Scenes\Gameplay"
call :MakeFolder "Assets\_Project\Scenes\Test"
call :MakeFolder "Assets\_Project\Scenes\Sandbox"

call :MakeFolder "Assets\_Project\Scripts"
call :MakeFolder "Assets\_Project\Scripts\Core"
call :MakeFolder "Assets\_Project\Scripts\Gameplay"
call :MakeFolder "Assets\_Project\Scripts\AI"
call :MakeFolder "Assets\_Project\Scripts\UI"
call :MakeFolder "Assets\_Project\Scripts\Audio"
call :MakeFolder "Assets\_Project\Scripts\Networking"
call :MakeFolder "Assets\_Project\Scripts\Editor"
call :MakeFolder "Assets\_Project\Scripts\Tools"
call :MakeFolder "Assets\_Project\Scripts\Testing"

call :MakeFolder "Assets\_Project\Settings"
call :MakeFolder "Assets\_Project\Shaders"

call :MakeFolder "Assets\_Project\UI"
call :MakeFolder "Assets\_Project\UI\Fonts"
call :MakeFolder "Assets\_Project\UI\Icons"
call :MakeFolder "Assets\_Project\UI\Layouts"
call :MakeFolder "Assets\_Project\UI\Themes"
call :MakeFolder "Assets\_Project\UI\Screens"

call :MakeFolder "Assets\_Project\VFX"
call :MakeFolder "Assets\_Project\Testing"

echo.
echo Folder structure creation complete.
echo.

popd
exit /b 0

:MakeFolder
if not exist "%~1" (
    mkdir "%~1"
    echo Created: %~1
) else (
    echo Exists:  %~1
)
exit /b 0
