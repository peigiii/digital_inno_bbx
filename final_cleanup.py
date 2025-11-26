#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import glob

TRANSLATIONS = {
    '侧边': 'Side',
    '冒伪劣': 'Counterfeit',
    '实': 'Real',
    '己': 'Self',
    '措': 'Measure',
    '棕榈油': 'Palm Oil',
    '棕榈油厂': 'Palm Oil Mill',
    '营业执': 'Business License',
    '线下': 'Offline',
    '邮件': 'Email',
    '邮寄': 'Mail',
    '垃圾': 'Trash',
    '专业': 'Professional',
    '实惠': 'Affordable',
    '周边': 'Nearby',
    '撰写': 'Write',
    '替代': 'Replace',
    '兴趣': 'Interest',
    '负': 'Negative',
    '较': 'More',
    '额': 'Amount',
    '审': 'Audit',
    '寻': 'Search',
    '废': 'Waste',
    '循': 'Cycle',
    '性': 'Nature',
    '托': 'Trust',
    '拨': 'Dial',
    '描': 'Desc',
    '敏': 'Sensitive',
    '栏': 'Bar',
    '款': 'Fund',
    '殊': 'Special',
    '济': 'Economy',
    '混': 'Mix',
    '滤': 'Filter',
    '然': 'Then',
    '疑': 'Doubt',
    '筑': 'Build',
    '筛': 'Filter',
    '纬': 'Lat',
    '纺织': 'Textile',
    '线': 'Line',
    '编': 'Edit',
    '至': 'To',
    '良': 'Good',
    '要': 'Want',
    '规': 'Rule',
    '角': 'Angle',
    '谨': 'Caution',
    '慎': 'Caution',
    '钓': 'Fish',
    '钮': 'Button',
    '颁': 'Award',
    '驳': 'Reject',
    '串': 'String',
    '习': 'Practice',
    '争': 'Fight',
    '于': 'At',
    '交': 'Hand over',
    '产': 'Produce',
    '享': 'Enjoy',
    '仅': 'Only',
    '们': 's', # Plural suffix, tricky
    '价': 'Price',
    '任': 'Task',
    '优': 'Good',
    '似': 'Like',
    '但': 'But',
    '使': 'Make',
    '例': 'Example',
    '供': 'Supply',
    '保': 'Protect',
    '信': 'Trust',
    '先': 'First',
    '写': 'Write',
    '况': 'Situation',
    '凭': 'Proof',
    '切': 'Cut',
    '利': 'Profit',
    '功': 'Merit',
    '升': 'Rise',
    '卓': 'Super',
    '单': 'Single',
    '占': 'Occupy',
    '及': 'And',
    '各': 'Each',
    '吗': '?',
    '售': 'Sell',
    '因': 'Cause',
    '在': 'At',
    '底': 'Bottom',
    '将': 'Will',
    '并': 'And',
    '应': 'Should',
    '您': 'You',
    '这': 'This',
    '遇': 'Meet',
    '都': 'All',
    '上': 'Up',
    '下': 'Down',
    '不': 'No',
    '了': 'ed',
    '人': 'Person',
}

def replace_in_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original_content = content
        
        # Sort keys by length descending
        sorted_keys = sorted(TRANSLATIONS.keys(), key=len, reverse=True)
        
        for cn in sorted_keys:
            if cn in content:
                content = content.replace(cn, TRANSLATIONS[cn])
                
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    print("Starting Final Cleanup...")
    dart_files = glob.glob('lib/**/*.dart', recursive=True)
    
    count = 0
    for filepath in dart_files:
        if replace_in_file(filepath):
            print(f"Updated: {filepath}")
            count += 1
            
    print(f"\nFinished! Updated {count} files.")

if __name__ == '__main__':
    main()

