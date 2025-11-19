# 模拟器网络连接问题修复指南

## 问题描述
应用卡在启动画面（Logo），无法连接到 Firestore，错误信息：
```
Unable to resolve host "firestore.googleapis.com": No address associated with hostname
```

## 已修复的代码问题 ✅

### 1. 主线程阻塞问题
- ✅ 将所有初始化操作从 `main()` 函数移到后台
- ✅ 应用现在立即启动，不等待网络连接
- ✅ 添加了所有操作的超时处理

### 2. 添加的超时保护
- Firebase 初始化：10 秒超时
- 用户文档初始化：10 秒超时
- 权限请求：每个 5 秒超时
- 通知服务：5 秒超时
- SplashScreen 用户检查：3 秒超时

## 模拟器网络问题修复方案

### 方案 1: 重启模拟器 (推荐)
```powershell
# 在 PowerShell 中执行
# 1. 停止当前运行的模拟器
# 2. 重新启动模拟器
```

### 方案 2: 配置模拟器 DNS

1. **打开 Android 模拟器的设置**
   - Settings → Network & Internet → Internet
   - 点击右侧的齿轮图标

2. **配置 DNS**
   - IP settings: Static
   - DNS 1: `8.8.8.8` (Google DNS)
   - DNS 2: `8.8.4.4` (Google 备用 DNS)

3. **保存并重启模拟器**

### 方案 3: 使用真实设备测试

如果模拟器网络问题持续存在，建议使用真实 Android 设备：

```powershell
# 1. 启用开发者选项和 USB 调试
# 2. 连接设备到电脑
# 3. 运行以下命令
flutter devices
flutter run -d <device-id>
```

### 方案 4: 检查防火墙和代理设置

1. **关闭防火墙/杀毒软件**（临时）
2. **检查是否使用了代理**
3. **确保模拟器可以访问互联网**

### 方案 5: 重新创建模拟器

如果以上方法都不行：

1. 打开 Android Studio
2. Tools → Device Manager
3. 删除当前模拟器
4. 创建新的模拟器（推荐 Pixel 7 + API 34）

## 验证修复

运行以下命令重新测试：

```powershell
cd digital_inno_bbx
flutter clean
flutter pub get
flutter run
```

## 预期行为

修复后的应用应该：
1. ✅ 立即显示启动画面（2 秒）
2. ✅ 即使网络失败也能正常进入登录页
3. ✅ 后台初始化不阻塞 UI
4. ✅ 所有操作都有超时保护

## 调试日志

启动时会看到以下日志：
- `✅ Firebase 初始化成功` - Firebase 正常
- `⚠️ Firebase 初始化超时` - Firebase 超时（应用仍会启动）
- `✅ 权限请求完成` - 权限请求完成
- `✅ 用户文档初始化完成` - 用户数据准备好
- `⚠️ 获取用户信息超时，跳转到登录页` - 超时后正常跳转

## 常见问题

### Q: 应用还是卡住怎么办？
A: 
1. 完全关闭应用
2. 运行 `flutter clean`
3. 重启模拟器
4. 重新运行 `flutter run`

### Q: 网络连接正常但还是显示错误？
A: 
1. 检查 Firebase 配置文件是否正确
2. 确认 `google-services.json` 存在
3. 检查 Firebase 项目是否启用了 Firestore

### Q: 真实设备也有问题？
A: 
1. 检查设备网络连接
2. 尝试切换 WiFi/移动数据
3. 清除应用数据重新安装

## 技术说明

修复的核心逻辑：
- 应用启动不再依赖网络连接
- 所有网络操作都在后台异步执行
- 失败不会影响应用的基本功能
- 用户可以正常使用离线功能

## 联系支持

如果问题仍然存在，请提供：
1. 完整的错误日志
2. 模拟器配置信息
3. Flutter 版本信息（`flutter doctor`）

