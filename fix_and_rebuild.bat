@echo off
chcp 65001 >nul
REM 编码问题修复和重新编译脚本 (Windows)
REM 用法: fix_and_rebuild.bat

echo ==================================================
echo   BBX 编码问题修复和重新编译
echo ==================================================
echo.

REM 检查当前分支
echo 📌 步骤 1: 检查当前分支...
git branch --show-current
echo.

REM 拉取最新修复
echo 📥 步骤 2: 拉取最新修复...
git pull origin claude/fix-chinese-encoding-016A2yVe2az2MYzyE5bKJe8q
echo.

REM 验证中文字符完整性
echo 🔍 步骤 3: 验证中文字符完整性...
findstr /C:"用户未登录" lib\services\chat_service.dart >nul && (
    echo ✓ chat_service.dart - 中文字符完整
) || (
    echo ✗ chat_service.dart - 可能有问题
)

findstr /C:"生产者" lib\models\user_model.dart >nul && (
    echo ✓ user_model.dart - 中文字符完整
) || (
    echo ✗ user_model.dart - 可能有问题
)
echo.

REM 清理构建缓存
echo 🧹 步骤 4: 清理 Flutter 构建缓存...
flutter clean
echo.

REM 删除 dart_tool
echo 🗑️  步骤 5: 删除 .dart_tool 目录...
if exist .dart_tool (
    rmdir /s /q .dart_tool
    echo .dart_tool 已删除
)
echo.

REM 获取依赖
echo 📦 步骤 6: 获取 Flutter 依赖...
flutter pub get
echo.

REM 检查语法
echo 🔍 步骤 7: 检查代码语法...
echo 运行 flutter analyze...
flutter analyze
echo.

echo ==================================================
echo ✅ 清理和准备工作完成！
echo ==================================================
echo.
echo 现在可以运行以下命令编译：
echo.
echo   flutter run          # 运行应用
echo   flutter build apk    # 构建 APK
echo.
pause
