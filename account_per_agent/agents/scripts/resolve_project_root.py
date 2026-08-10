#!/usr/bin/env python3
import sys
import json
import os

def find_git_root(file_path):
    curr = os.path.dirname(os.path.abspath(file_path))
    while curr and curr != "/":
        if os.path.exists(os.path.join(curr, ".git")):
            return curr
        curr = os.path.dirname(curr)
    return os.path.dirname(os.path.abspath(file_path))

def main():
    try:
        data = json.load(sys.stdin)
        tool_call = data.get("toolCall", {})
        args = tool_call.get("args", {})
        
        # Get target file path
        target_file = args.get("file") or args.get("filePath") or args.get("path") or args.get("AbsolutePath") or args.get("TargetFile")
        
        result = {"decision": "allow"}
        
        if target_file:
            project_root = find_git_root(target_file)
            # Output info to stderr for logging/debugging
            sys.stderr.write(f"[PreToolUse Hook] File: {target_file} -> Resolved Project Root: {project_root}\n")
            
            # Export to environment for downstream processes
            os.environ["IJ_MCP_SERVER_PROJECT_PATH"] = project_root
            
            # Return allow decision
            print(json.dumps(result))
            return
            
    except Exception as e:
        sys.stderr.write(f"[PreToolUse Hook Error] {e}\n")

    print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()
