"""
Remote tools for executing commands on the school EDA server via SSH.

Configuration in config.py:
    REMOTE_HOST  — hostname or IP of the school server
    REMOTE_USER  — your username
    REMOTE_KEY   — path to your SSH private key (default: ~/.ssh/id_rsa)
    REMOTE_WORK_DIR — working directory on the remote server

SSH must be set up (public key auth recommended). Test with:
    ssh <REMOTE_USER>@<REMOTE_HOST>
before using these tools.
"""

import os
import config

REMOTE_TOOLS = [
    {
        "name": "run_remote_command",
        "description": (
            "Run a command on the remote school EDA server via SSH. "
            "Use this to execute Innovus, synthesis tools, or any other "
            "EDA commands available only on the server. "
            "Returns stdout, stderr, and exit code."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "command": {
                    "type": "string",
                    "description": (
                        "Shell command to run on the remote server. "
                        "Example: 'innovus -batch -source /path/to/run.tcl'"
                    )
                }
            },
            "required": ["command"]
        }
    },
    {
        "name": "upload_to_remote",
        "description": (
            "Upload a local file to the remote school EDA server via SCP/SFTP. "
            "Use this to send Verilog designs, TCL scripts, or constraint files "
            "before running EDA tools remotely."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "local_path": {
                    "type": "string",
                    "description": "Local file path relative to project root, e.g. 'designs/adder4.v'"
                },
                "remote_path": {
                    "type": "string",
                    "description": "Absolute path on the remote server, e.g. '/home/user/ic_agent/designs/adder4.v'"
                }
            },
            "required": ["local_path", "remote_path"]
        }
    },
    {
        "name": "download_from_remote",
        "description": (
            "Download a file from the remote school EDA server to local. "
            "Use this to retrieve Innovus outputs, reports, or layout files."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "remote_path": {
                    "type": "string",
                    "description": "Absolute path on the remote server"
                },
                "local_path": {
                    "type": "string",
                    "description": "Local destination path relative to project root, e.g. 'results/adder4.gds'"
                }
            },
            "required": ["remote_path", "local_path"]
        }
    }
]


def execute_remote_tool(tool_name: str, tool_input: dict) -> str:
    if not _check_config():
        return (
            "ERROR: Remote server not configured. "
            "Please set REMOTE_HOST, REMOTE_USER in config.py first."
        )

    if tool_name == "run_remote_command":
        return _run_remote_command(tool_input["command"])
    elif tool_name == "upload_to_remote":
        return _upload_file(tool_input["local_path"], tool_input["remote_path"])
    elif tool_name == "download_from_remote":
        return _download_file(tool_input["remote_path"], tool_input["local_path"])
    return f"ERROR: Unknown remote tool '{tool_name}'"


def _check_config() -> bool:
    return bool(getattr(config, "REMOTE_HOST", "") and getattr(config, "REMOTE_USER", ""))


def _get_ssh_client():
    try:
        import paramiko
    except ImportError:
        raise RuntimeError("paramiko not installed. Run: pip install paramiko")

    key_path = os.path.expanduser(getattr(config, "REMOTE_KEY", "~/.ssh/id_rsa"))
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(
        hostname=config.REMOTE_HOST,
        username=config.REMOTE_USER,
        key_filename=key_path,
        timeout=30
    )
    return ssh


def _run_remote_command(command: str) -> str:
    try:
        ssh = _get_ssh_client()
        stdin, stdout, stderr = ssh.exec_command(command, timeout=300)
        out = stdout.read().decode("utf-8", errors="replace")
        err = stderr.read().decode("utf-8", errors="replace")
        exit_code = stdout.channel.recv_exit_status()
        ssh.close()

        parts = []
        if out:
            parts.append(f"[stdout]\n{out.rstrip()}")
        if err:
            parts.append(f"[stderr]\n{err.rstrip()}")
        parts.append(f"[exit code] {exit_code}")
        return "\n".join(parts)
    except Exception as e:
        return f"ERROR (SSH): {e}"


def _upload_file(local_path: str, remote_path: str) -> str:
    try:
        local_full = os.path.join(config.WORK_DIR, local_path)
        if not os.path.exists(local_full):
            return f"ERROR: Local file '{local_path}' not found"

        ssh = _get_ssh_client()
        sftp = ssh.open_sftp()

        # Ensure remote directory exists
        remote_dir = os.path.dirname(remote_path)
        try:
            ssh.exec_command(f"mkdir -p {remote_dir}")
        except Exception:
            pass

        sftp.put(local_full, remote_path)
        sftp.close()
        ssh.close()
        return f"OK: Uploaded '{local_path}' → {remote_path}"
    except Exception as e:
        return f"ERROR (upload): {e}"


def _download_file(remote_path: str, local_path: str) -> str:
    try:
        local_full = os.path.join(config.WORK_DIR, local_path)
        os.makedirs(os.path.dirname(local_full), exist_ok=True)

        ssh = _get_ssh_client()
        sftp = ssh.open_sftp()
        sftp.get(remote_path, local_full)
        sftp.close()
        ssh.close()
        return f"OK: Downloaded {remote_path} → '{local_path}'"
    except Exception as e:
        return f"ERROR (download): {e}"
