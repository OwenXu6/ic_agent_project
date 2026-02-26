import os
import config

FILE_TOOLS = [
    {
        "name": "write_file",
        "description": (
            "Write content to a file. Use this to create or overwrite Verilog design files, "
            "testbenches, TCL scripts, or any other project file. "
            "Path is relative to the project work directory."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Relative file path, e.g. 'designs/adder4.v' or 'scripts/run_innovus.tcl'"
                },
                "content": {
                    "type": "string",
                    "description": "The full content to write into the file"
                }
            },
            "required": ["path", "content"]
        }
    },
    {
        "name": "read_file",
        "description": (
            "Read and return the content of a file. "
            "Path is relative to the project work directory."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Relative file path to read"
                }
            },
            "required": ["path"]
        }
    },
    {
        "name": "list_files",
        "description": "List all files in a directory (relative to the project work directory).",
        "input_schema": {
            "type": "object",
            "properties": {
                "directory": {
                    "type": "string",
                    "description": "Relative directory path. Use '.' for the project root."
                }
            },
            "required": ["directory"]
        }
    }
]


def execute_file_tool(tool_name: str, tool_input: dict) -> str:
    if tool_name == "write_file":
        return _write_file(tool_input["path"], tool_input["content"])
    elif tool_name == "read_file":
        return _read_file(tool_input["path"])
    elif tool_name == "list_files":
        return _list_files(tool_input["directory"])
    return f"ERROR: Unknown file tool '{tool_name}'"


def _resolve(relative_path: str) -> str:
    full = os.path.join(config.WORK_DIR, relative_path)
    # Security: ensure the resolved path is within WORK_DIR
    real = os.path.realpath(full)
    work_real = os.path.realpath(config.WORK_DIR)
    if not real.startswith(work_real):
        raise ValueError(f"Path '{relative_path}' escapes the work directory")
    return full


def _write_file(path: str, content: str) -> str:
    try:
        full_path = _resolve(path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, "w", encoding="utf-8") as f:
            f.write(content)
        return f"OK: Written {len(content)} bytes to '{path}'"
    except Exception as e:
        return f"ERROR: {e}"


def _read_file(path: str) -> str:
    try:
        full_path = _resolve(path)
        with open(full_path, "r", encoding="utf-8") as f:
            content = f.read()
        return content if content else "(empty file)"
    except FileNotFoundError:
        return f"ERROR: File '{path}' not found"
    except Exception as e:
        return f"ERROR: {e}"


def _list_files(directory: str) -> str:
    try:
        full_path = _resolve(directory)
        entries = []
        for root, dirs, files in os.walk(full_path):
            # Skip hidden directories
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            rel_root = os.path.relpath(root, config.WORK_DIR)
            for fname in files:
                entries.append(os.path.join(rel_root, fname))
        if not entries:
            return f"(no files in '{directory}')"
        return "\n".join(sorted(entries))
    except Exception as e:
        return f"ERROR: {e}"
