import glob
import re
import os

def find_chinese_strings():
    # Ensure we are searching inside the digital_inno_bbx directory if we are not already there
    base_dir = os.getcwd()
    print(f"Current working directory: {base_dir}")
    
    if os.path.basename(base_dir) == 'digital_inno_bbx':
        search_paths = ['lib/**/*.dart', 'test/**/*.dart']
    else:
        search_paths = ['digital_inno_bbx/lib/**/*.dart', 'digital_inno_bbx/test/**/*.dart']
        
    unique_strings = set()
    chinese_pattern = re.compile(r'[\u4e00-\u9fa5]+')
    
    for path_pattern in search_paths:
        print(f"Searching in: {path_pattern}")
        dart_files = glob.glob(path_pattern, recursive=True)
        
        for filepath in dart_files:
            try:
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    matches = chinese_pattern.findall(content)
                    for match in matches:
                        unique_strings.add(match)
            except Exception as e:
                print(f"Error reading {filepath}: {e}")

    print(f"Found {len(unique_strings)} unique Chinese strings.")
    
    for s in sorted(unique_strings):
        print(s)

if __name__ == '__main__':
    find_chinese_strings()
