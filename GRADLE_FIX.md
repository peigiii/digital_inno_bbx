# 修复 Gradle 编译错误

## 问题描述
编译时出现 Kotlin 增量编译缓存错误：
```
java.lang.IllegalArgumentException: this and base files have different roots
```

## 解决方案

### 方法 1: 清理所有缓存（推荐）
在项目根目录执行以下命令：

```bash
# 1. 清理 Flutter 缓存
flutter clean

# 2. 删除 build 文件夹
rmdir /s /q build           # Windows
rm -rf build                # Mac/Linux

# 3. 删除 .gradle 文件夹
rmdir /s /q .gradle         # Windows
rm -rf .gradle              # Mac/Linux

# 4. 清理 Android Gradle 缓存
cd android
gradlew clean               # Windows
./gradlew clean             # Mac/Linux
cd ..

# 5. 重新获取依赖
flutter pub get

# 6. 重新构建
flutter run
```

### 方法 2: 快速清理（如果方法1不工作）
```bash
# 停止 Gradle Daemon
cd android
gradlew --stop              # Windows
./gradlew --stop            # Mac/Linux
cd ..

# 删除全局 Gradle 缓存
# Windows: %USERPROFILE%\.gradle\caches
# Mac/Linux: ~/.gradle/caches
rmdir /s /q %USERPROFILE%\.gradle\caches     # Windows
rm -rf ~/.gradle/caches                      # Mac/Linux

# 重新构建
flutter clean
flutter pub get
flutter run
```

### 方法 3: 如果问题持续存在
```bash
# 1. 升级 Gradle 版本
# 编辑 android/gradle/wrapper/gradle-wrapper.properties
# 将 distributionUrl 更新为最新版本

# 2. 升级 Kotlin 版本
# 编辑 android/build.gradle
# 更新 kotlin_version

# 3. 重新尝试
flutter clean
flutter pub get
flutter run
```

## 预防措施

1. **定期清理缓存**：每周运行一次 `flutter clean`
2. **避免路径问题**：确保项目路径不包含中文或特殊字符
3. **使用最新版本**：保持 Flutter、Gradle 和 Kotlin 版本最新
4. **关闭 IDE**：清理缓存时关闭 Android Studio 或 VS Code

## 注意事项

- 清理缓存会删除所有编译产物，首次重新构建会较慢
- 如果使用 Android Studio，也需要 `Invalidate Caches and Restart`
- 确保有稳定的网络连接来重新下载依赖
