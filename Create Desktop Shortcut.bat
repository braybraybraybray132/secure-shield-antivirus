@echo off
REM Creates a "Guardian Shield" shortcut on your Desktop.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\Guardian Shield.lnk'); $s.TargetPath='%~dp0Start Guardian Shield.bat'; $s.WorkingDirectory='%~dp0'; $s.IconLocation='%SystemRoot%\System32\SecurityHealthSystray.exe,0'; $s.WindowStyle=7; $s.Save()"
echo.
echo Done! A "Guardian Shield" shortcut is now on your Desktop.
pause
