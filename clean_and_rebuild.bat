@echo off
echo 正在彻底清理项目...

REM 关闭可能锁定文件的进程（可选）
echo 请确保已关闭 VS Code、Android Studio 等 IDE

REM 删除构建产物
echo 删除 build 目录...
rmdir /s /q build 2>nul

REM 删除 .dart_tool
echo 删除 .dart_tool 目录...
rmdir /s /q .dart_tool 2>nul

REM 删除 .flutter-plugins 相关文件
echo 删除 Flutter 插件缓存...
del /f /q .flutter-plugins 2>nul
del /f /q .flutter-plugins-dependencies 2>nul
del /f /q .packages 2>nul
del /f /q pubspec.lock 2>nul

REM 删除平台特定的构建产物
echo 删除平台构建目录...
rmdir /s /q android\.gradle 2>nul
rmdir /s /q android\app\build 2>nul
rmdir /s /q android\build 2>nul
rmdir /s /q ios\.symlinks 2>nul
rmdir /s /q ios\Pods 2>nul
rmdir /s /q ios\build 2>nul

echo.
echo 清理完成！现在重新获取依赖...
echo.

REM 重新获取依赖
flutter pub get

echo.
echo 完成！现在可以运行 flutter run
pause
