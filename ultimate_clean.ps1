# ============================================================================
# BBX Project Ultimate Clean Script - Fix All Compilation Issues
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BBX Ultimate Clean Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Step 1: Kill all related processes
# ============================================================================

Write-Host "[1/6] Killing all Dart/Flutter/Kotlin/Gradle processes..." -ForegroundColor Yellow

$processesToKill = @(
    "dart",
    "dartaotruntime",
    "flutter",
    "flutter_tools",
    "analysis_server",
    "java",
    "javaw",
    "gradle",
    "kotlin-compiler-daemon",
    "kotlin-daemon-client",
    "gradlew"
)

foreach ($processName in $processesToKill) {
    try {
        $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($processes) {
            Write-Host "  -> Killing $processName processes ($($processes.Count))..." -ForegroundColor Gray
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }
    } catch {
        # Ignore errors
    }
}

Write-Host "  [OK] Process cleanup completed" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 2: Delete project local cache
# ============================================================================

Write-Host "[2/6] Deleting project local cache..." -ForegroundColor Yellow

$foldersToDelete = @(
    "build",
    ".dart_tool",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".packages",
    "android\.gradle",
    "android\app\build",
    "android\build",
    "android\.idea",
    "ios\.symlinks",
    "ios\Pods",
    "ios\build",
    "macos\build",
    "windows\build",
    "linux\build",
    ".idea"
)

foreach ($folder in $foldersToDelete) {
    if (Test-Path $folder) {
        Write-Host "  -> Deleting $folder..." -ForegroundColor Gray
        try {
            # Remove read-only attributes first
            Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue |
                ForEach-Object { $_.Attributes = 'Normal' }

            # Force delete
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            # If still fails, use cmd rmdir
            cmd /c "rmdir /s /q `"$folder`"" 2>$null
        }
    }
}

# Delete individual files
$filesToDelete = @(
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".packages",
    "pubspec.lock"
)

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Write-Host "  -> Deleting $file..." -ForegroundColor Gray
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "  [OK] Project cache cleanup completed" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 3: Delete global Gradle cache
# ============================================================================

Write-Host "[3/6] Deleting global Gradle cache..." -ForegroundColor Yellow

$gradleHome = "$env:USERPROFILE\.gradle"
if (Test-Path $gradleHome) {
    Write-Host "  -> Deleting $gradleHome\caches..." -ForegroundColor Gray
    Remove-Item -Path "$gradleHome\caches" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "  -> Deleting $gradleHome\daemon..." -ForegroundColor Gray
    Remove-Item -Path "$gradleHome\daemon" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  [OK] Gradle cache cleanup completed" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 4: Delete Flutter Pub cache
# ============================================================================

Write-Host "[4/6] Deleting Flutter Pub cache..." -ForegroundColor Yellow

$pubCache = "$env:LOCALAPPDATA\Pub\Cache"
if (Test-Path $pubCache) {
    # Only delete shared_preferences_android related cache
    $sharedPrefPackages = Get-ChildItem -Path "$pubCache\hosted\pub.dev" -Filter "shared_preferences*" -ErrorAction SilentlyContinue
    foreach ($pkg in $sharedPrefPackages) {
        Write-Host "  -> Deleting $($pkg.Name)..." -ForegroundColor Gray
        Remove-Item -Path $pkg.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "  [OK] Pub cache cleanup completed" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 5: Clean Kotlin compilation cache
# ============================================================================

Write-Host "[5/6] Cleaning Kotlin compilation cache..." -ForegroundColor Yellow

$kotlinDaemonDir = "$env:USERPROFILE\.kotlin"
if (Test-Path $kotlinDaemonDir) {
    Write-Host "  -> Deleting Kotlin daemon cache..." -ForegroundColor Gray
    Remove-Item -Path $kotlinDaemonDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  [OK] Kotlin cache cleanup completed" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Step 6: Reinitialize project
# ============================================================================

Write-Host "[6/6] Reinitializing project..." -ForegroundColor Yellow

Write-Host "  -> Running flutter pub get..." -ForegroundColor Gray
flutter pub get

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run: flutter run" -ForegroundColor Cyan
Write-Host ""
