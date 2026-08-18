@echo off
title BBJOMS

set "ROOT=%~dp0"

echo.
echo ========================================
echo                BBJOMS 
echo ========================================
echo.

echo Starting Backend...
start "BBJOMS Backend" cmd /k "cd /d "%ROOT%backend" && npm run dev"

echo Waiting for backend...
timeout /t 5 /nobreak >nul

echo Starting Frontend...
cd /d "%ROOT%frontend"

flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000


pause