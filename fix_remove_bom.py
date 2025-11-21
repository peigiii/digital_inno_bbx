#!/usr/bin/env python3
"""
从所有 Dart 文件移除 UTF-8 BOM
"""

import os
import codecs
import glob

def remove_bom_if_exists(file_path):
    """从文件移除 UTF-8 BOM（如果有）"""
    try:
        # 读取文件
        with open(file_path, 'rb') as f:
            content = f.read()

        # 检查是否有 BOM
        has_bom = content.startswith(codecs.BOM_UTF8)

        if has_bom:
            # 移除 BOM
            with open(file_path, 'wb') as f:
                f.write(content[len(codecs.BOM_UTF8):])
            return True
        return False
    except Exception as e:
        print(f"错误处理 {file_path}: {e}")
        return False

def main():
    print("=" * 60)
    print("  从 Dart 文件移除 UTF-8 BOM")
    print("=" * 60)
    print()

    # 查找所有 Dart 文件
    dart_files = glob.glob('lib/**/*.dart', recursive=True)

    print(f"找到 {len(dart_files)} 个 Dart 文件")
    print()

    removed_count = 0
    skipped_count = 0

    for file_path in dart_files:
        if remove_bom_if_exists(file_path):
            print(f"✓ 已移除 BOM: {file_path}")
            removed_count += 1
        else:
            skipped_count += 1

    print()
    print("=" * 60)
    print(f"完成! 移除 BOM: {removed_count} 个文件, 跳过: {skipped_count} 个文件")
    print("=" * 60)
    print()

if __name__ == '__main__':
    main()
