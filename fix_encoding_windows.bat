@echo off
chcp 65001 >nul
REM ============================================
REM Flutter Windows 编码问题完整修复方案
REM ============================================

echo.
echo ========================================
echo   BBX Flutter 编码问题修复工具
echo ========================================
echo.

REM 步骤 1: 设置 UTF-8 代码页
echo [1/8] 设置系统代码页为 UTF-8...
chcp 65001
echo.

REM 步骤 2: 设置环境变量
echo [2/8] 设置 Flutter 环境变量...
set LANG=en_US.UTF-8
set LC_ALL=en_US.UTF-8
echo   LANG=%LANG%
echo   LC_ALL=%LC_ALL%
echo.

REM 步骤 3: 检查 Flutter 版本
echo [3/8] 检查 Flutter 版本...
flutter --version
echo.

REM 步骤 4: 停止所有 Dart 进程
echo [4/8] 停止所有 Dart/Flutter 进程...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM java.exe 2>nul
timeout /t 2 /nobreak >nul
echo   进程已停止
echo.

REM 步骤 5: 彻底清理缓存
echo [5/8] 彻底清理所有缓存...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
if exist .flutter-plugins del /f /q .flutter-plugins
if exist .flutter-plugins-dependencies del /f /q .flutter-plugins-dependencies
if exist android\build rmdir /s /q android\build
if exist android\.gradle rmdir /s /q android\.gradle
if exist ios\Pods rmdir /s /q ios\Pods
if exist ios\.symlinks rmdir /s /q ios\.symlinks

REM 清理 Flutter 全局缓存
echo   清理 Flutter 全局缓存...
flutter clean
echo.

REM 步骤 6: 验证文件编码
echo [6/8] 验证关键文件的中文字符...
findstr /C:"用户未登录" lib\services\payment_service.dart >nul && (
    echo   ✓ payment_service.dart - 中文字符正常
) || (
    echo   ✗ payment_service.dart - 中文字符异常
)

findstr /C:"生产者" lib\models\user_model.dart >nul && (
    echo   ✓ user_model.dart - 中文字符正常
) || (
    echo   ✗ user_model.dart - 中文字符异常
)

findstr /C:"已支付" lib\models\transaction_model.dart >nul && (
    echo   ✓ transaction_model.dart - 中文字符正常
) || (
    echo   ✗ transaction_model.dart - 中文字符异常
)
echo.

REM 步骤 7: 重新获取依赖
echo [7/8] 重新获取 Flutter 依赖...
flutter pub get
echo.

REM 步骤 8: 运行分析
echo [8/8] 运行 Flutter 分析（仅显示前30行）...
flutter analyze 2>&1 | findstr /V "^$" | more +1
echo.

echo ========================================
echo   修复完成！
echo ========================================
echo.
echo 如果仍有编码错误，请尝试以下方案：
echo.
echo   方案 A - 在 PowerShell 管理员模式下运行：
echo   ----------------------------------------
echo   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -Name 'ACP' -Value '65001'
echo   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -Name 'OEMCP' -Value '65001'
echo   然后重启电脑
echo.
echo   方案 B - 使用 Visual Studio Code：
echo   ----------------------------------------
echo   1. 打开 VS Code
echo   2. 按 Ctrl+Shift+P
echo   3. 输入 "Change File Encoding"
echo   4. 选择 "Reopen with Encoding"
echo   5. 选择 "UTF-8"
echo.
echo   方案 C - 尝试使用 UTF-8 with BOM：
echo   ----------------------------------------
echo   运行: python fix_add_bom.py
echo.
echo 现在可以运行：
echo   flutter run
echo.
pause
