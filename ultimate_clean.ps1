# ============================================================================
# BBX 项目终极清理脚本 - 解决所有编译问题
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BBX 项目终极清理脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# 第一步：杀掉所有相关进程
# ============================================================================

Write-Host "[1/6] 杀掉所有 Dart/Flutter/Kotlin/Gradle 进程..." -ForegroundColor Yellow

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
            Write-Host "  → 杀掉 $processName 进程 ($($processes.Count) 个)..." -ForegroundColor Gray
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }
    } catch {
        # 忽略错误
    }
}

Write-Host "  ✓ 进程清理完成" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 第二步：删除项目本地缓存
# ============================================================================

Write-Host "[2/6] 删除项目本地缓存..." -ForegroundColor Yellow

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
        Write-Host "  → 删除 $folder..." -ForegroundColor Gray
        try {
            # 先尝试移除只读属性
            Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue |
                ForEach-Object { $_.Attributes = 'Normal' }

            # 强制删除
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            # 如果还是失败，使用 cmd rmdir
            cmd /c "rmdir /s /q `"$folder`"" 2>$null
        }
    }
}

# 删除单个文件
$filesToDelete = @(
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".packages",
    "pubspec.lock"
)

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Write-Host "  → 删除 $file..." -ForegroundColor Gray
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "  ✓ 项目缓存清理完成" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 第三步：删除全局 Gradle 缓存
# ============================================================================

Write-Host "[3/6] 删除全局 Gradle 缓存..." -ForegroundColor Yellow

$gradleHome = "$env:USERPROFILE\.gradle"
if (Test-Path $gradleHome) {
    Write-Host "  → 删除 $gradleHome\caches..." -ForegroundColor Gray
    Remove-Item -Path "$gradleHome\caches" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "  → 删除 $gradleHome\daemon..." -ForegroundColor Gray
    Remove-Item -Path "$gradleHome\daemon" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  ✓ Gradle 缓存清理完成" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 第四步：删除 Flutter 全局缓存
# ============================================================================

Write-Host "[4/6] 删除 Flutter Pub 缓存..." -ForegroundColor Yellow

$pubCache = "$env:LOCALAPPDATA\Pub\Cache"
if (Test-Path $pubCache) {
    # 只删除 shared_preferences_android 相关缓存
    $sharedPrefPackages = Get-ChildItem -Path "$pubCache\hosted\pub.dev" -Filter "shared_preferences*" -ErrorAction SilentlyContinue
    foreach ($pkg in $sharedPrefPackages) {
        Write-Host "  → 删除 $($pkg.Name)..." -ForegroundColor Gray
        Remove-Item -Path $pkg.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "  ✓ Pub 缓存清理完成" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 第五步：清理 Kotlin 编译缓存
# ============================================================================

Write-Host "[5/6] 清理 Kotlin 编译缓存..." -ForegroundColor Yellow

$kotlinDaemonDir = "$env:USERPROFILE\.kotlin"
if (Test-Path $kotlinDaemonDir) {
    Write-Host "  → 删除 Kotlin daemon 缓存..." -ForegroundColor Gray
    Remove-Item -Path $kotlinDaemonDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  ✓ Kotlin 缓存清理完成" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 第六步：重新初始化项目
# ============================================================================

Write-Host "[6/6] 重新初始化项目..." -ForegroundColor Yellow

Write-Host "  → 运行 flutter pub get..." -ForegroundColor Gray
flutter pub get

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "清理完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "现在可以运行：flutter run" -ForegroundColor Cyan
Write-Host ""
