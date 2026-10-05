@echo off
cd /d "%~dp0"
if not exist "assets\actors\zombie.tscn" (
    echo Missing game assets. Follow docs\ASSETS.md before launching.
    pause
    exit /b 1
)
if exist "..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" (
    start "PVZ Godot" "..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
    exit /b 0
)
where godot >nul 2>nul
if not errorlevel 1 (
    start "PVZ Godot" godot --path "%~dp0."
    exit /b 0
)
where godot4 >nul 2>nul
if not errorlevel 1 (
    start "PVZ Godot" godot4 --path "%~dp0."
    exit /b 0
)
echo Godot 4.7.2 was not found. Import project.godot in Godot to run the game.
pause
exit /b 1
