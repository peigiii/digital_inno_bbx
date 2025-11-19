# ===============================================
# Flutter Build Issues Fix Script (PowerShell)
# This script fixes Kotlin cache corruption and ADB issues
# ===============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Flutter Build Issues Fix Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop Gradle daemon
Write-Host "[1/6] Stopping Gradle daemon processes..." -ForegroundColor Yellow
Set-Location android
.\gradlew --stop
Set-Location ..

# Step 2: Clean Flutter
Write-Host ""
Write-Host "[2/6] Cleaning Flutter build artifacts..." -ForegroundColor Yellow
flutter clean

# Step 3: Delete corrupted caches
Write-Host ""
Write-Host "[3/6] Deleting corrupted Kotlin caches..." -ForegroundColor Yellow

if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "Build directory deleted." -ForegroundColor Green
}

if (Test-Path "android\.gradle") {
    Remove-Item -Path "android\.gradle" -Recurse -Force
    Write-Host "Android .gradle directory deleted." -ForegroundColor Green
}

$gradleCaches = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCaches) {
    try {
        Remove-Item -Path $gradleCaches -Recurse -Force -ErrorAction Stop
        Write-Host "User Gradle caches deleted." -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not delete some Gradle cache files (they may be in use)" -ForegroundColor Yellow
    }
}

# Step 4: Restart ADB
Write-Host ""
Write-Host "[4/6] Restarting ADB server..." -ForegroundColor Yellow
adb kill-server
Start-Sleep -Seconds 2
adb start-server
Start-Sleep -Seconds 3

# Step 5: Get dependencies
Write-Host ""
Write-Host "[5/6] Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# Step 6: Build
Write-Host ""
Write-Host "[6/6] Rebuilding the application..." -ForegroundColor Yellow
flutter build apk --debug

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Build fix completed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Start your emulator" -ForegroundColor White
Write-Host "2. Run: flutter run" -ForegroundColor White
Write-Host ""
