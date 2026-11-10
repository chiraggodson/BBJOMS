@echo off
setlocal
title BBJOMS - Git Pull
cd /d "%~dp0"
if errorlevel 1 exit /b 1

echo.
echo ==============================
echo        BBJOMS Git Pull
echo ==============================
echo.
for /f "delims=" %%i in ('git status --porcelain') do (
    echo ERROR: The working tree has local changes.
    echo Review or save them before pulling:
    echo %%i
    echo.
    pause
    exit /b 1
)

git pull --ff-only
if errorlevel 1 (
    echo.
    echo Pull stopped. Review the Git message above; no merge was attempted.
    echo.
    pause
    exit /b 1
)

echo.
pause
