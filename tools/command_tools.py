import subprocess
import os
import config

COMMAND_TOOLS = [
    {
        "name": "run_local_command",
        "description": (
            "Run a shell command locally. Use this for: "
            "iverilog/vvp simulation, git add/commit/push, "
            "file inspection, or any local operation. "
            "The command runs inside the project work directory by default. "
            "Returns stdout, stderr, and exit code."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "command": {
                    "type": "string",
                    "description": "Shell command to run, e.g. 'iverilog -o results/sim tb/adder_tb.v designs/adder.v'"
                },
                "cwd": {
                    "type": "string",
                    "description": "Working directory relative to project root. Defaults to project root ('.')."
                }
            },
            "required": ["command"]
        }
    }
]


def execute_command_tool(tool_name: str, tool_input: dict) -> str:
    if tool_name == "run_local_command":
        return _run_local_command(
            tool_input["command"],
            tool_input.get("cwd", ".")
        )
    return f"ERROR: Unknown command tool '{tool_name}'"


def _run_local_command(command: str, cwd: str = ".") -> str:
    work_dir = os.path.join(config.WORK_DIR, cwd)
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=work_dir,
            capture_output=True,
            text=True,
            timeout=120
        )
        parts = []
        if result.stdout:
            parts.append(f"[stdout]\n{result.stdout.rstrip()}")
        if result.stderr:
            parts.append(f"[stderr]\n{result.stderr.rstrip()}")
        parts.append(f"[exit code] {result.returncode}")
        return "\n".join(parts) if parts else f"[exit code] {result.returncode}"
    except subprocess.TimeoutExpired:
        return "ERROR: Command timed out after 120 seconds"
    except Exception as e:
        return f"ERROR: {e}"
