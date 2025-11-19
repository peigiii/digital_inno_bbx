@echo off
REM ===============================================
REM Flutter Build Issues Fix Script
REM This script fixes Kotlin cache corruption and ADB issues
REM ===============================================

echo.
echo ============================================
echo Flutter Build Issues Fix Script
echo ============================================
echo.

echo [1/6] Stopping Gradle daemon processes...
cd android
call gradlew --stop
cd ..

echo.
echo [2/6] Cleaning Flutter build artifacts...
call flutter clean

echo.
echo [3/6] Deleting corrupted Kotlin caches...
if exist "build\" (
    rmdir /s /q "build"
    echo Build directory deleted.
)
if exist "android\.gradle\" (
    rmdir /s /q "android\.gradle"
    echo Android .gradle directory deleted.
)
if exist "%USERPROFILE%\.gradle\caches\" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches"
    echo User Gradle caches deleted.
)

echo.
echo [4/6] Restarting ADB server...
adb kill-server
timeout /t 2 /nobreak >nul
adb start-server
timeout /t 3 /nobreak >nul

echo.
echo [5/6] Getting Flutter dependencies...
call flutter pub get

echo.
echo [6/6] Rebuilding the application...
call flutter build apk --debug

echo.
echo ============================================
echo Build fix completed!
echo ============================================
echo.
echo Next steps:
echo 1. Start your emulator
echo 2. Run: flutter run
echo.
pause
