from tools.file_tools import FILE_TOOLS, execute_file_tool
from tools.command_tools import COMMAND_TOOLS, execute_command_tool
from tools.remote_tools import REMOTE_TOOLS, execute_remote_tool

ALL_TOOLS = FILE_TOOLS + COMMAND_TOOLS + REMOTE_TOOLS


def execute_tool(tool_name: str, tool_input: dict) -> str:
    if tool_name in [t["name"] for t in FILE_TOOLS]:
        return execute_file_tool(tool_name, tool_input)
    elif tool_name in [t["name"] for t in COMMAND_TOOLS]:
        return execute_command_tool(tool_name, tool_input)
    elif tool_name in [t["name"] for t in REMOTE_TOOLS]:
        return execute_remote_tool(tool_name, tool_input)
    else:
        return f"ERROR: Unknown tool '{tool_name}'"
