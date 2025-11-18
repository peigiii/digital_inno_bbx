# BBX 应用部署指南

## 📋 目录
1. [前置要求](#前置要求)
2. [Firebase 配置](#firebase-配置)
3. [Firestore 安全规则部署](#firestore-安全规则部署)
4. [Firestore 索引创建](#firestore-索引创建)
5. [Flutter 应用构建](#flutter-应用构建)
6. [应用商店发布](#应用商店发布)

---

## 前置要求

### 开发环境
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode（用于构建移动应用）
- Firebase CLI

### Firebase 项目设置
1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 创建新项目或使用现有项目
3. 启用以下服务：
   - Authentication (Email/Password)
   - Cloud Firestore
   - Cloud Storage (可选，用于图片上传)
   - Cloud Functions (可选，用于后台任务)

---

## Firebase 配置

### 1. 安装 Firebase CLI

```bash
# 使用 npm 安装
npm install -g firebase-tools

# 登录 Firebase
firebase login
```

### 2. 初始化 Firebase 项目

```bash
# 在项目根目录
firebase init

# 选择以下服务：
# - Firestore
# - Storage (可选)
# - Functions (可选)
```

### 3. 配置 Flutter Firebase

项目已经包含 `firebase_options.dart`，如果需要重新生成：

```bash
# 安装 FlutterFire CLI
dart pub global activate flutterfire_cli

# 配置 Firebase
flutterfire configure
```

---

## Firestore 安全规则部署

### 1. 部署安全规则

项目中的 `firestore.rules` 文件包含了完整的安全规则。部署命令：

```bash
firebase deploy --only firestore:rules
```

### 2. 验证安全规则

部署后，在 Firebase Console 中验证：
1. 进入 **Firestore Database** → **Rules** 标签
2. 确认规则已更新
3. 使用模拟器测试规则

### 3. 重要的安全规则说明

#### Users Collection
- ✅ 所有认证用户可以读取用户资料
- ✅ 用户只能更新自己的资料
- ✅ 只有管理员可以删除用户

#### Waste Listings Collection
- ✅ 所有认证用户可以浏览列表
- ✅ 只有创建者可以编辑/删除自己的列表
- ✅ 状态必须从 'available' 开始

#### Offers Collection
- ✅ 报价双方（生产者和回收商）可以查看
- ✅ 回收商可以创建报价
- ✅ 生产者可以接受/拒绝报价

#### Conversations Collection
- ✅ 只有对话参与者可以访问
- ✅ 支持消息已读状态更新

---

## Firestore 索引创建

### 自动创建索引

当您运行应用并触发特定查询时，Firebase 会提示创建索引。点击控制台中的链接即可自动创建。

### 手动创建索引

在 Firebase Console → **Firestore Database** → **Indexes** 中创建以下索引：

#### 1. Offers 索引
```
Collection: offers
Fields:
- status (Ascending)
- createdAt (Descending)
```

#### 2. Waste Listings 索引
```
Collection: waste_listings
Fields:
- status (Ascending)
- createdAt (Descending)
```

#### 3. Messages 索引
```
Collection: conversations/{conversationId}/messages
Fields:
- receiverId (Ascending)
- read (Ascending)
```

### 使用 Firebase CLI 部署索引

创建 `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "offers",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "waste_listings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "receiverId", "order": "ASCENDING" },
        { "fieldPath": "read", "order": "ASCENDING" }
      ]
    }
  ]
}
```

部署：
```bash
firebase deploy --only firestore:indexes
```

---

## Flutter 应用构建

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 检查代码

```bash
# 分析代码
flutter analyze

# 格式化代码
flutter format .
```

### 3. 构建 Android APK

```bash
# Debug 版本
flutter build apk --debug

# Release 版本
flutter build apk --release

# Release 版本（分架构）
flutter build apk --release --split-per-abi
```

生成的文件位置：
- `build/app/outputs/flutter-apk/app-release.apk`

### 4. 构建 Android App Bundle (推荐用于 Google Play)

```bash
flutter build appbundle --release
```

生成的文件位置：
- `build/app/outputs/bundle/release/app-release.aab`

### 5. 构建 iOS IPA

```bash
# 确保已配置签名证书
flutter build ios --release

# 在 Xcode 中打开项目
open ios/Runner.xcworkspace

# 在 Xcode 中 Archive 并导出
```

---

## 应用商店发布

### Google Play Store

#### 1. 准备工作
- [ ] 创建应用图标（512x512 PNG）
- [ ] 准备应用截图（多种尺寸）
- [ ] 编写应用描述（英文和中文）
- [ ] 准备隐私政策 URL
- [ ] 创建内容分级问卷

#### 2. 签名配置

创建 `android/key.properties`:
```properties
storePassword=<您的密钥库密码>
keyPassword=<您的密钥密码>
keyAlias=upload
storeFile=<密钥库文件路径>
```

创建密钥库：
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

更新 `android/app/build.gradle`:
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 3. 上传到 Google Play Console
1. 访问 [Google Play Console](https://play.google.com/console/)
2. 创建新应用
3. 上传 AAB 文件
4. 填写应用详情
5. 提交审核

### Apple App Store

#### 1. 准备工作
- [ ] 注册 Apple Developer 账号（$99/年）
- [ ] 创建 App ID
- [ ] 配置证书和 Provisioning Profile
- [ ] 准备应用图标和截图
- [ ] 编写应用描述

#### 2. 配置 Info.plist

在 `ios/Runner/Info.plist` 中添加权限描述：
```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机以拍摄废料照片</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要访问位置以显示附近的废料列表</string>
```

#### 3. 上传到 App Store Connect
1. 在 Xcode 中 Archive
2. Validate App
3. Distribute App
4. 在 App Store Connect 中填写应用信息
5. 提交审核

---

## 环境变量配置

### 开发环境

创建 `.env.development`:
```
FIREBASE_PROJECT_ID=your-project-dev
FIREBASE_API_KEY=your-api-key-dev
```

### 生产环境

创建 `.env.production`:
```
FIREBASE_PROJECT_ID=your-project-prod
FIREBASE_API_KEY=your-api-key-prod
```

---

## 监控和分析

### 1. Firebase Crashlytics

启用崩溃报告：
```bash
flutter pub add firebase_crashlytics
```

### 2. Google Analytics

启用用户分析：
```bash
flutter pub add firebase_analytics
```

### 3. Performance Monitoring

启用性能监控：
```bash
flutter pub add firebase_performance
```

---

## 版本发布检查清单

发布前确保：

- [ ] 更新 `pubspec.yaml` 中的版本号
- [ ] 更新 `android/app/build.gradle` 中的 versionCode 和 versionName
- [ ] 更新 `ios/Runner/Info.plist` 中的 CFBundleShortVersionString
- [ ] 运行所有测试：`flutter test`
- [ ] 检查代码质量：`flutter analyze`
- [ ] 移除所有调试代码和测试数据初始化
- [ ] 确认 Firestore 安全规则已部署
- [ ] 确认所有 Firebase 索引已创建
- [ ] 测试支付流程（如果已集成）
- [ ] 准备发布说明
- [ ] 备份数据库

---

## 故障排查

### 常见问题

#### 1. Firestore 权限错误
```
Error: Missing or insufficient permissions
```
**解决方案**: 确认已部署 firestore.rules

#### 2. 索引缺失
```
Error: The query requires an index
```
**解决方案**: 点击错误消息中的链接创建索引

#### 3. 构建失败
```
Gradle build failed
```
**解决方案**:
- 清理项目：`flutter clean && flutter pub get`
- 检查 Android SDK 版本
- 更新 Gradle 版本

---

## 支持

如有问题，请查阅：
- [Flutter 文档](https://flutter.dev/docs)
- [Firebase 文档](https://firebase.google.com/docs)
- [项目审计报告](AUDIT_REPORT.md)

---

**最后更新**: 2025-11-18
**版本**: 1.0.0
