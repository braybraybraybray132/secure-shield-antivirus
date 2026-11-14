@echo off
REM Starts Guardian Shield. Keep this file in the same folder as all the other Guardian Shield files.
cd /d "%~dp0"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0GuardianShield.ps1"
