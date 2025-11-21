#!/bin/bash

# 编码问题修复和重新编译脚本
# 用法: bash fix_and_rebuild.sh

echo "=================================================="
echo "  BBX 编码问题修复和重新编译"
echo "=================================================="
echo ""

# 检查当前分支
echo "📌 步骤 1: 检查当前分支..."
CURRENT_BRANCH=$(git branch --show-current)
echo "当前分支: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "claude/fix-chinese-encoding-016A2yVe2az2MYzyE5bKJe8q" ]; then
    echo "⚠️  警告: 你不在正确的分支上"
    echo "正在切换到修复分支..."
    git checkout claude/fix-chinese-encoding-016A2yVe2az2MYzyE5bKJe8q
fi

echo ""

# 拉取最新修复
echo "📥 步骤 2: 拉取最新修复..."
git pull origin claude/fix-chinese-encoding-016A2yVe2az2MYzyE5bKJe8q

echo ""

# 验证中文字符完整性
echo "🔍 步骤 3: 验证中文字符完整性..."
echo "检查关键文件..."

if grep -q "用户未登录" lib/services/chat_service.dart; then
    echo "✓ chat_service.dart - 中文字符完整"
else
    echo "✗ chat_service.dart - 可能有问题"
fi

if grep -q "生产者" lib/models/user_model.dart; then
    echo "✓ user_model.dart - 中文字符完整"
else
    echo "✗ user_model.dart - 可能有问题"
fi

if grep -q "账户设置" lib/screens/profile/bbx_optimized_profile_screen.dart; then
    echo "✓ bbx_optimized_profile_screen.dart - 中文字符完整"
else
    echo "✗ bbx_optimized_profile_screen.dart - 可能有问题"
fi

echo ""

# 清理构建缓存
echo "🧹 步骤 4: 清理 Flutter 构建缓存..."
flutter clean

echo ""

# 删除 dart_tool
echo "🗑️  步骤 5: 删除 .dart_tool 目录..."
rm -rf .dart_tool

echo ""

# 获取依赖
echo "📦 步骤 6: 获取 Flutter 依赖..."
flutter pub get

echo ""

# 检查语法
echo "🔍 步骤 7: 检查代码语法..."
flutter analyze | head -50

echo ""
echo "=================================================="
echo "✅ 清理和准备工作完成！"
echo "=================================================="
echo ""
echo "现在可以运行以下命令编译："
echo ""
echo "  flutter run          # 运行应用"
echo "  flutter build apk    # 构建 APK"
echo ""
