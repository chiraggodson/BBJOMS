@echo off
title BBJOMS - Git Backup
cd /d "%~dp0"

echo.
echo ==========================================
echo          BBJOMS Git Backup
echo ==========================================
echo.

echo [1/4] Checking Git status...
echo.
git status

echo.
echo ==========================================
set /p "msg=Enter commit message: "

if "%msg%"=="" (
    echo.
    echo ERROR: Commit message cannot be empty.
    echo.
    pause
    exit /b 1
)

echo.
echo [2/4] Adding changes...
git add .

if errorlevel 1 (
    echo.
    echo ERROR: Git add failed.
    echo.
    pause
    exit /b 1
)

echo.
echo [3/4] Creating commit...
git commit -m "%msg%"

if errorlevel 1 (
    echo.
    echo ERROR: Git commit failed.
    echo.
    pause
    exit /b 1
)

echo.
echo [4/4] Pushing to GitHub...
git push

if errorlevel 1 (
    echo.
    echo ==========================================
    echo ERROR: Push failed.
    echo ==========================================
    echo.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo       BACKUP COMPLETED SUCCESSFULLY
echo ==========================================
echo.
echo Your BBJOMS changes are now pushed to GitHub.
echo.

git status

echo.
pause