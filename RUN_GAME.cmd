@echo off
cd /d "%~dp0"
where python >nul 2>nul
if errorlevel 1 (
  echo Python 3 is required. You can also open index.html directly.
  pause
  exit /b 1
)
echo School and Sprout - Desktop Playtest
echo Open http://127.0.0.1:8937 in your browser.
echo Keep this window open while playing. Press Ctrl+C to stop.
python game\serve.py
pause
