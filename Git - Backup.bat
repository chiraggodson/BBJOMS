@echo off
setlocal DisableDelayedExpansion
title BBJOMS - Git Backup
cd /d "%~dp0"
if errorlevel 1 exit /b 1

echo.
echo ==========================================
echo          BBJOMS Git Backup
echo ==========================================
echo.
echo Current changes:
echo.
git status --short
if errorlevel 1 exit /b 1

echo.
echo Staging changes so they can be reviewed:
git add -A
if errorlevel 1 (
    echo ERROR: Git could not stage the changes.
    pause
    exit /b 1
)

echo.
echo Files staged for commit:
echo.
git diff --cached --name-only
if errorlevel 1 exit /b 1

echo.
git diff --cached --stat
if errorlevel 1 exit /b 1

echo.
set /p "confirm=Commit the staged files shown above? (Y/N): "
if /I not "%confirm%"=="Y" (
    echo.
    echo No commit created. Staged files remain available for review.
    pause
    exit /b 0
)

echo.
set /p "msg=Enter commit message: "
if "%msg%"=="" (
    echo ERROR: Commit message cannot be empty.
    pause
    exit /b 1
)

git commit -m "%msg%"
if errorlevel 1 (
    echo.
    echo Commit failed. Review the Git message above.
    pause
    exit /b 1
)

echo.
set /p "pushConfirm=Push this commit to the remote repository? (Y/N): "
if /I not "%pushConfirm%"=="Y" (
    echo.
    echo Commit saved locally. Nothing was pushed.
    git status --short
    pause
    exit /b 0
)

git push
if errorlevel 1 (
    echo.
    echo Push failed. Your local commit remains saved.
    pause
    exit /b 1
)

echo.
echo Backup completed successfully.
echo.
git status --short
pause
