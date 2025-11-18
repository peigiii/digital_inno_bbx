@echo off
echo ========================================
echo BBX 应用完全清理脚本
echo ========================================
echo.

echo [1/6] 停止 Gradle daemon...
cd android
call gradlew --stop 2>nul
cd ..
echo     完成!
echo.

echo [2/6] 删除构建缓存...
if exist build (
    rmdir /s /q build
    echo     删除 build 目录
)
if exist android\.gradle (
    rmdir /s /q android\.gradle
    echo     删除 android\.gradle 目录
)
if exist android\build (
    rmdir /s /q android\build
    echo     删除 android\build 目录
)
if exist .dart_tool (
    rmdir /s /q .dart_tool
    echo     删除 .dart_tool 目录
)
if exist .flutter-plugins-dependencies (
    del /f .flutter-plugins-dependencies
    echo     删除 .flutter-plugins-dependencies 文件
)
echo     完成!
echo.

echo [3/6] 执行 Flutter clean...
call flutter clean
echo     完成!
echo.

echo [4/6] 获取依赖包...
call flutter pub get
echo     完成!
echo.

echo ========================================
echo 清理完成！
echo ========================================
echo.
echo 现在可以运行: flutter run
echo.
pause
