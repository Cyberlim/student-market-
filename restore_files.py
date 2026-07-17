import json
import os
import re
import glob

transcript_path = 'C:/Users/alok/.gemini/antigravity-ide/brain/46bdfd51-8c70-4f98-a86a-35081cfc7e42/.system_generated/logs/transcript_full.jsonl'

files = {}
original_paths = {}

def normalize_path(path):
    if not path:
        return ""
    return os.path.abspath(path).replace('\\', '/').lower()

# Initialize files dict from current disk files (in case they already have some pre-existing contents)
print("Initializing files from disk...")
for d in ['frontend/lib', 'admin_app/lib']:
    for f in glob.glob(d + '/**/*.dart', recursive=True):
        if os.path.isfile(f):
            norm = normalize_path(f)
            original_paths[norm] = os.path.abspath(f)
            # Read only if it is not 0 bytes (empty)
            if os.path.getsize(f) > 0:
                with open(f, 'r', encoding='utf-8') as file_obj:
                    files[norm] = file_obj.read()
                print(f"Loaded pre-existing {f} ({len(files[norm])} bytes)")

print("\nPlaying back transcript...")
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line_num, line in enumerate(f):
        try:
            obj = json.loads(line)
        except Exception:
            continue
            
        tool_calls = obj.get("tool_calls", [])
        if not tool_calls:
            continue
            
        for tc in tool_calls:
            name = tc.get("name")
            args = tc.get("args", {})
            
            if name == "write_to_file":
                target = args.get("TargetFile")
                if target and target.lower().endswith(".dart") and "std" in target.lower():
                    norm = normalize_path(target)
                    original_paths[norm] = target
                    files[norm] = args.get("CodeContent", "")
                    print(f"Line {line_num}: write_to_file -> {target} ({len(files[norm])} bytes)")
                    
            elif name == "replace_file_content":
                target = args.get("TargetFile")
                if target and target.lower().endswith(".dart") and "std" in target.lower():
                    norm = normalize_path(target)
                    original_paths[norm] = target
                    target_content = args.get("TargetContent", "")
                    replacement_content = args.get("ReplacementContent", "")
                    
                    if norm in files:
                        orig = files[norm]
                        if target_content in orig:
                            files[norm] = orig.replace(target_content, replacement_content)
                            print(f"Line {line_num}: replace_file_content -> {target} (Success)")
                        else:
                            # Fuzzy fallback: try replacing all spaces/newlines with flexible regex safely
                            print(f"Line {line_num}: replace_file_content -> {target} (Exact match failed, trying fuzzy)")
                            try:
                                escaped_target = re.escape(target_content)
                                pattern = re.sub(r'\\s+', r'\\s+', escaped_target)
                                pattern = re.sub(r'\s+', r'\\s+', pattern)
                                new_content, count = re.subn(pattern, lambda m: replacement_content, orig)
                                if count > 0:
                                    files[norm] = new_content
                                    print(f"Line {line_num}: replace_file_content -> {target} (Fuzzy Success)")
                                else:
                                    print(f"Line {line_num}: replace_file_content -> {target} (Failed to match target)")
                            except Exception as e:
                                print(f"Line {line_num}: replace_file_content error: {e}")
                    else:
                        print(f"Line {line_num}: replace_file_content -> {target} (File not initialized)")
                        
            elif name == "multi_replace_file_content":
                target = args.get("TargetFile")
                if target and target.lower().endswith(".dart") and "std" in target.lower():
                    norm = normalize_path(target)
                    original_paths[norm] = target
                    chunks = args.get("ReplacementChunks", [])
                    
                    if norm in files:
                        print(f"Line {line_num}: multi_replace_file_content -> {target} ({len(chunks)} chunks)")
                        for chunk_idx, chunk in enumerate(chunks):
                            orig = files[norm]
                            target_content = chunk.get("TargetContent", "")
                            replacement_content = chunk.get("ReplacementContent", "")
                            if target_content in orig:
                                files[norm] = orig.replace(target_content, replacement_content)
                                print(f"  Chunk {chunk_idx}: Success")
                            else:
                                print(f"  Chunk {chunk_idx}: Exact match failed, trying fuzzy")
                                try:
                                    escaped_target = re.escape(target_content)
                                    pattern = re.sub(r'\\s+', r'\\s+', escaped_target)
                                    pattern = re.sub(r'\s+', r'\\s+', pattern)
                                    new_content, count = re.subn(pattern, lambda m: replacement_content, orig)
                                    if count > 0:
                                        files[norm] = new_content
                                        print(f"  Chunk {chunk_idx}: Fuzzy Success")
                                    else:
                                        print(f"  Chunk {chunk_idx}: Failed to match target")
                                except Exception as e:
                                    print(f"  Chunk {chunk_idx} error: {e}")
                    else:
                        print(f"Line {line_num}: multi_replace_file_content -> {target} (File not initialized)")

print("\nWriting restored files to disk...")
for norm, content in files.items():
    orig_path = original_paths[norm]
    print(f"Restoring {orig_path} ({len(content)} bytes)")
    os.makedirs(os.path.dirname(orig_path), exist_ok=True)
    with open(orig_path, 'w', encoding='utf-8') as out_f:
        out_f.write(content)

print("\nRestoration complete!")
