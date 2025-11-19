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

## 最新更新记录

### 2025-11-19: 底部导航与个人中心完整重构

#### 新增组件
1. **底部导航栏** (`lib/widgets/navigation/bbx_bottom_navigation.dart`)
   - 5个Tab：首页、商品、发布（凸起）、消息、个人中心
   - 中间发布按钮凸起设计
   - 未读消息角标支持

#### 新增页面
2. **个人中心页面** (`lib/screens/profile/bbx_profile_screen.dart`)
   - 完整的用户信息展示
   - 账户管理区域（钱包、会员、积分）
   - 我的服务区域（商品、报价、交易、收藏）
   - 会员专区（2x2网格布局）
   - 设置区域
   - 帮助与支持

3. **钱包页面** (`lib/screens/profile/bbx_wallet_screen.dart`)
   - 余额显示
   - 充值/提现功能
   - 交易记录列表

4. **优惠券页面** (`lib/screens/profile/bbx_coupons_screen.dart`)
   - Tab切换：可用、已使用、已过期
   - 精美的优惠券卡片设计
   - 优惠券使用功能

5. **统计页面** (`lib/screens/profile/bbx_statistics_screen.dart`)
   - 财务概览（收入、支出、利润）
   - 业务统计（发布、报价、交易、浏览）
   - 评价统计（评分分布）
   - 月度趋势图表占位

6. **账户设置页面** (`lib/screens/profile/bbx_account_settings_screen.dart`)
   - 个人信息编辑
   - 公司信息
   - 账户安全（邮箱验证、修改密码、实名认证）
   - 危险操作（删除账户）

7. **通知设置页面** (`lib/screens/profile/bbx_notification_settings_screen.dart`)
   - 通知方式设置（推送、邮件、短信）
   - 通知类型设置（新报价、交易更新等）
   - 营销通知开关

#### 新增数据模型
8. **订阅模型** (`lib/models/subscription_model.dart`)
   - 支持4种订阅类型：Free, Basic, Professional, Enterprise
   - 订阅状态管理
   - 功能特性列表

9. **奖励模型** (`lib/models/reward_model.dart`)
   - 积分系统
   - 会员等级（Bronze, Silver, Gold, Platinum）
   - 奖励交易记录
   - 每日任务系统

10. **优惠券模型** (`lib/models/coupon_model.dart`)
    - 固定金额和百分比折扣
    - 优惠券状态管理
    - 最小使用金额限制
    - 折扣计算功能

#### 新增服务类
11. **订阅服务** (`lib/services/subscription_service.dart`)
    - 获取当前订阅
    - 订阅/取消订阅
    - 订阅状态检查

12. **奖励服务** (`lib/services/reward_service.dart`)
    - 积分获取与兑换
    - 每日任务管理
    - 会员等级升级

13. **钱包服务** (`lib/services/wallet_service.dart`)
    - 充值/提现
    - 支付/退款
    - 交易记录管理

#### 路由更新
在 `lib/main.dart` 中新增以下路由：
- `/profile` - 个人中心（更新为新版本）
- `/wallet` - 钱包
- `/rewards` - 奖励中心（已存在，重用）
- `/coupons` - 优惠券
- `/statistics` - 统计
- `/account-settings` - 账户设置
- `/notification-settings` - 通知设置

#### Firestore 集合需求
需要在 Firebase Console 创建以下集合：
```
subscriptions/      # 订阅记录
├── {userId}
    ├── planType
    ├── status
    ├── startDate
    ├── endDate
    ├── price
    └── features

rewards/            # 奖励积分
├── {userId}
    ├── points
    ├── tier
    ├── transactions[]
    └── dailyTasks[]

coupons/            # 优惠券
├── {couponId}
    ├── userId
    ├── code
    ├── discountType
    ├── discount
    ├── minAmount
    ├── status
    └── expiryDate

wallets/            # 钱包
├── {userId}
    ├── balance
    └── transactions[]

user_settings/      # 用户设置
├── {userId}
    └── notifications{}
```

#### 部署步骤
1. 拉取最新代码
   ```bash
   git pull origin claude/redesign-navigation-profile-01YRNUz5uhYHkHYkK8CWwQm2
   ```

2. 安装依赖
   ```bash
   flutter pub get
   ```

3. 创建 Firestore 集合（可通过应用首次使用自动创建）

4. 更新 Firestore 安全规则（添加新集合的权限）
   ```bash
   firebase deploy --only firestore:rules
   ```

5. 运行应用
   ```bash
   flutter run
   ```

6. 测试新功能
   - [ ] 测试底部导航栏切换
   - [ ] 测试个人中心所有菜单项
   - [ ] 测试钱包充值/提现
   - [ ] 测试优惠券显示
   - [ ] 测试统计数据展示
   - [ ] 测试账户设置保存
   - [ ] 测试通知设置保存

#### 后续优化建议
- [ ] 实现实际的支付集成（充值/提现）
- [ ] 添加图表库实现统计图表
- [ ] 实现实名认证流程
- [ ] 集成第三方支付（如 Stripe, PayPal）
- [ ] 添加优惠券自动应用功能
- [ ] 实现每日任务自动重置
- [ ] 添加会员权益详细说明页

#### 编译错误修复（2025-11-19）
**状态**: ✅ 已修复

修复了3个编译错误：
1. **bbx_profile_screen.dart:524** - 类型不匹配
   - 问题：trailing 参数需要 Widget? 类型，错误传入 String '中文'
   - 修复：将字符串包装成 Text widget

2. **bbx_profile_screen.dart:588** - 类型不匹配
   - 问题：trailing 参数需要 Widget? 类型，错误传入 String 'v1.0.0'
   - 修复：将字符串包装成 Text widget

3. **bbx_coupons_screen.dart:125** - 参数名称错误
   - 问题：BBXEmptyState 没有 subtitle 参数
   - 修复：将 subtitle 改为 description

详细信息请查看：`BUGFIX_REPORT_2025-11-19.md`

#### 20个编译错误修复（2025-11-19 批次2）
**状态**: ✅ 已修复

修复了20个编译错误，确保代码100%可运行：
1. **UserModel 属性名称** (10处)
   - photoUrl → photoURL (6处)
   - phone → contact (3处)

2. **ListingModel 属性名称** (2处)
   - scrapType → wasteType (1处)
   - expectedPrice → pricePerUnit (1处)

3. **OfferModel 属性名称** (2处)
   - amount → offerPrice (1处)
   - pickupDate → scheduledPickupDate (1处)

4. **服务方法修正** (3处)
   - getListingById() → getListing() (2处)
   - 移除不支持的 userId 参数 (1处)

5. **组件使用修正** (6处)
   - BBXLoading() → BBXFullScreenLoading() (6处profile页面)

详细信息请查看：`BUGFIX_REPORT_2025-11-19_BATCH2.md`

#### 旧版UI显示问题修复（2025-11-19）
**状态**: ✅ 已修复
**优先级**: P0（紧急）

**问题描述**：
用户启动应用后看到旧版UI（BBX Users页面），而不是新设计的UI。

**根本原因**：
1. `bbx_splash_screen.dart` 跳转到旧的 `BBXHomeScreen`
2. `BBXHomeScreen` 包含旧的5个Tab（Users/Listings/Recyclers/Offers/Messages）
3. 新UI文件已创建但缺少主页面包装器

**修复内容**：
1. **创建主页面包装器** - `lib/screens/bbx_main_screen.dart`
   - 管理5个新Tab页面切换
   - 使用 IndexedStack 保持页面状态
   - 集成 BBXBottomNavigation 新导航栏

2. **修改启动页跳转** - `lib/screens/bbx_splash_screen.dart`
   - 从跳转 BBXHomeScreen → 改为跳转 BBXMainScreen

3. **修改路由配置** - `lib/main.dart`
   - '/home' 路由从 BBXHomeScreen → 改为 BBXMainScreen

**新UI架构**：
```
BBXMainScreen (主页面)
├── IndexedStack (保持状态)
│   ├── BBXNewHomeScreen (首页)
│   ├── BBXNewMarketplaceScreen (商品)
│   ├── BBXListWasteScreen (发布)
│   ├── BBXConversationsScreen (消息)
│   └── BBXProfileScreen (个人中心)
└── BBXBottomNavigation (底部导航)
    └── 5个Tab + 凸起的发布按钮
```

**预期效果**：
- ✅ 首页显示 "BBX Marketplace" 而非 "BBX Users"
- ✅ 底部导航：首页/商品/发布/消息/我的
- ✅ 中间发布按钮凸起设计（64x64，向上8px）
- ✅ 新的个人中心完整显示（渐变头部、会员专区等）

详细信息请查看：`UI_FIX_REPORT_2025-11-19.md`

---

**最后更新**: 2025-11-19
**版本**: 1.2.0
**构建状态**: ✅ 所有编译错误已修复，新UI已启用
