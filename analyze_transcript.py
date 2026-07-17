import json

transcript_path = 'C:/Users/alok/.gemini/antigravity-ide/brain/46bdfd51-8c70-4f98-a86a-35081cfc7e42/.system_generated/logs/transcript_full.jsonl'

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line_num, line in enumerate(f):
        try:
            obj = json.loads(line)
        except Exception:
            continue
        tc_list = obj.get("tool_calls", [])
        for tc in tc_list:
            if tc.get("name") == "view_file":
                target = tc.get("args", {}).get("AbsolutePath") or ""
                if "note_detail_screen.dart" in target.lower():
                    print(f"Line {line_num}: view_file args={tc.get('args')}")
