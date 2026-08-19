@echo off
title BBJOMS - Git Commit
cd /d "%~dp0"

echo.
echo ==============================
echo        BBJOMS Git Commit
echo ==============================
echo.

git status

echo.
set /p "msg=Enter commit message: "

if "%msg%"=="" (
    echo.
    echo ERROR: Commit message cannot be empty.
    pause
    exit /b 1
)

echo.
echo Adding changes...
git add .

echo.
echo Committing...
git commit -m "%msg%"

echo.
pause