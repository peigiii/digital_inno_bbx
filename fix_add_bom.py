#!/usr/bin/env python3
"""
为所有 Dart 文件添加 UTF-8 BOM
用于解决 Windows 上的编码识别问题
"""

import os
import codecs
import glob

def add_bom_if_needed(file_path):
    """为文件添加 UTF-8 BOM（如果还没有）"""
    try:
        # 读取文件
        with open(file_path, 'rb') as f:
            content = f.read()

        # 检查是否已有 BOM
        has_bom = content.startswith(codecs.BOM_UTF8)

        if not has_bom:
            # 添加 BOM
            with open(file_path, 'wb') as f:
                f.write(codecs.BOM_UTF8 + content)
            return True
        return False
    except Exception as e:
        print(f"错误处理 {file_path}: {e}")
        return False

def main():
    print("=" * 60)
    print("  为 Dart 文件添加 UTF-8 BOM")
    print("=" * 60)
    print()

    # 查找所有 Dart 文件
    dart_files = glob.glob('lib/**/*.dart', recursive=True)

    print(f"找到 {len(dart_files)} 个 Dart 文件")
    print()

    added_count = 0
    skipped_count = 0

    for file_path in dart_files:
        if add_bom_if_needed(file_path):
            print(f"✓ 已添加 BOM: {file_path}")
            added_count += 1
        else:
            skipped_count += 1

    print()
    print("=" * 60)
    print(f"完成! 添加 BOM: {added_count} 个文件, 跳过: {skipped_count} 个文件")
    print("=" * 60)
    print()
    print("重要提示：")
    print("1. 添加 BOM 后，请运行: flutter clean")
    print("2. 然后运行: flutter pub get")
    print("3. 最后运行: flutter run")
    print()
    print("如果问题仍然存在，请移除 BOM 并使用其他方案：")
    print("  python fix_remove_bom.py")
    print()

if __name__ == '__main__':
    main()
