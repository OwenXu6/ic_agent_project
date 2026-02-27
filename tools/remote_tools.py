"""
Remote tools for executing commands on the school EDA server via SSH.

Configuration in config.py:
    REMOTE_HOST         — hostname or IP of the school server
    REMOTE_USER         — your username
    REMOTE_KEY          — path to your SSH private key (default: password auth)
    REMOTE_PASSWORD     — password (if not using key auth)
    REMOTE_WORK_DIR     — working directory on the remote server
    REMOTE_PREP_COURSE  — course label for `prep` (default: "ECE260B_WI26_A00")

All EDA commands are run inside an interactive PTY session so that
`prep -l <COURSE>` can load the ACMS module environment (Innovus, etc.)
before your command executes. This is required on UCSD ieng6 because
the EDA binaries live on an NFS mount that is only activated by `prep`.
"""

import os
import re
import time

import config

REMOTE_TOOLS = [
    {
        "name": "sync_to_remote",
        "description": (
            "Sync the entire local project to the remote server in one call. "
            "Uploads all design files (Verilog, TCL, SDC, etc.) to REMOTE_WORK_DIR, "
            "creating subdirectories as needed. Skips credentials, git, and build artifacts. "
            "Always call this before running dc_shell or innovus on the remote server "
            "to make sure the server has the latest files."
        ),
        "input_schema": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "run_remote_command",
        "description": (
            "Run a command on the remote school EDA server via SSH. "
            "Automatically loads EDA tools (Innovus, Design Compiler, etc.) "
            "via `prep -l <COURSE>` before running your command, so you can "
            "call `innovus`, `dc_shell`, `xrun`, etc. directly. "
            "Returns prep output, command stdout/stderr, and exit code."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "command": {
                    "type": "string",
                    "description": (
                        "Shell command to run on the remote server. "
                        "Example: 'cd ~/ic_agent && innovus -batch -source scripts/innovus_pnr.tcl'"
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

    if tool_name == "sync_to_remote":
        return _sync_to_remote()
    elif tool_name == "run_remote_command":
        return _run_remote_command(tool_input["command"])
    elif tool_name == "upload_to_remote":
        return _upload_file(tool_input["local_path"], tool_input["remote_path"])
    elif tool_name == "download_from_remote":
        return _download_file(tool_input["remote_path"], tool_input["local_path"])
    return f"ERROR: Unknown remote tool '{tool_name}'"


# ── Internal helpers ──────────────────────────────────────────────────────────

def _check_config() -> bool:
    return bool(getattr(config, "REMOTE_HOST", "") and getattr(config, "REMOTE_USER", ""))


def _strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences and carriage returns from terminal output."""
    ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
    text = ansi_escape.sub("", text)
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text


def _get_ssh_client():
    try:
        import paramiko
    except ImportError:
        raise RuntimeError("paramiko not installed. Run: pip install paramiko")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    key_path = getattr(config, "REMOTE_KEY", "")
    password = getattr(config, "REMOTE_PASSWORD", "")

    if key_path:
        ssh.connect(
            hostname=config.REMOTE_HOST,
            username=config.REMOTE_USER,
            key_filename=os.path.expanduser(key_path),
            timeout=30,
        )
    else:
        ssh.connect(
            hostname=config.REMOTE_HOST,
            username=config.REMOTE_USER,
            password=password,
            timeout=30,
        )
    return ssh


def _sync_to_remote() -> str:
    """
    Walk the local project and upload every source file to REMOTE_WORK_DIR.

    Uploaded extensions: .v  .sv  .tcl  .sdc  .py (not config.py)  .txt  .md
    Skipped paths: .git/  __pycache__/  .env  config.py  results/  *.gitkeep
    """
    UPLOAD_EXTS = {".v", ".sv", ".tcl", ".sdc", ".txt", ".md"}
    SKIP_NAMES  = {"config.py", ".env", ".gitkeep"}
    SKIP_DIRS   = {".git", "__pycache__", "results", ".claude"}

    remote_base = getattr(config, "REMOTE_WORK_DIR",
                          f"/home/{config.REMOTE_USER}/ic_agent")

    try:
        ssh  = _get_ssh_client()
        sftp = ssh.open_sftp()

        # Ensure remote base directory exists
        ssh.exec_command(f"mkdir -p {remote_base}")
        time.sleep(0.5)

        uploaded = []
        skipped  = []

        for root, dirs, files in os.walk(config.WORK_DIR):
            # Prune skip dirs in-place so os.walk doesn't descend into them
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

            for fname in files:
                ext = os.path.splitext(fname)[1].lower()
                if fname in SKIP_NAMES:
                    skipped.append(fname)
                    continue
                if ext not in UPLOAD_EXTS:
                    skipped.append(fname)
                    continue

                local_abs  = os.path.join(root, fname)
                rel_path   = os.path.relpath(local_abs, config.WORK_DIR)
                remote_abs = remote_base + "/" + rel_path.replace(os.sep, "/")
                remote_dir = os.path.dirname(remote_abs)

                # Create remote subdirectory if needed
                ssh.exec_command(f"mkdir -p {remote_dir}")
                time.sleep(0.1)

                sftp.put(local_abs, remote_abs)
                uploaded.append(rel_path)

        sftp.close()
        ssh.close()

        lines = [f"Synced to {remote_base}"]
        lines.append(f"  Uploaded ({len(uploaded)}):")
        for f in sorted(uploaded):
            lines.append(f"    {f}")
        if skipped:
            lines.append(f"  Skipped  ({len(skipped)}): {', '.join(sorted(set(skipped)))}")
        return "\n".join(lines)

    except Exception as exc:
        return f"ERROR (sync_to_remote): {exc}"


def _run_remote_command(command: str) -> str:
    """
    Run *command* on the remote server inside an interactive PTY session.

    Flow:
      1. Open an interactive shell (PTY) — this triggers ~/.bashrc / login init.
      2. Drain the MOTD / initial banner.
      3. Run `prep -l <COURSE>` to load ACMS EDA modules (Innovus, etc.).
      4. Run the user's command.
      5. Echo a unique sentinel so we know when the command finishes.
      6. Return cleaned-up output (ANSI stripped, exit code included).
    """
    prep_course = getattr(config, "REMOTE_PREP_COURSE", "ECE260B_WI26_A00")
    ts = int(time.time())
    prep_sentinel = f"__PREP_DONE_{ts}__"
    cmd_sentinel  = f"__CMD_DONE_{ts}__"

    try:
        import paramiko
    except ImportError:
        return "ERROR: paramiko not installed. Run: pip install paramiko"

    try:
        ssh = _get_ssh_client()
        chan = ssh.invoke_shell(width=220, height=50)

        # ── helper: accumulate output until sentinel or timeout ──────────────
        def _wait_for(sentinel: str, timeout: int) -> str:
            buf = ""
            deadline = time.time() + timeout
            while time.time() < deadline:
                if chan.recv_ready():
                    chunk = chan.recv(8192).decode("utf-8", errors="replace")
                    buf += chunk
                    if sentinel in buf:
                        return buf
                else:
                    time.sleep(0.1)
            return buf + f"\n[TIMEOUT after {timeout}s — sentinel not seen]"

        # ── 1. Drain initial banner / MOTD ───────────────────────────────────
        time.sleep(2)
        while chan.recv_ready():
            chan.recv(4096)

        # ── 2. Load EDA tools via module system ──────────────────────────────────
        # `prep` is not available in a PTY session; use `module` directly.
        # The course modulefiles live at /home/linux/ieng6/<COURSE>/public/modulefiles
        module_dir = f"/home/linux/ieng6/{prep_course}/public/modulefiles"
        setup_cmd  = f"module use {module_dir} && module load {prep_course}"
        chan.send(f"{setup_cmd} 2>&1; echo '{prep_sentinel}'\n")
        prep_raw = _wait_for(prep_sentinel, timeout=90)
        prep_clean = _strip_ansi(prep_raw.split(prep_sentinel)[0]).strip()

        # ── 3. Run user command; capture exit code; echo sentinel ────────────
        chan.send(f"{command} 2>&1; echo \"EXIT_CODE:$?\"; echo '{cmd_sentinel}'\n")
        cmd_raw = _wait_for(cmd_sentinel, timeout=300)

        ssh.close()

        # ── 4. Parse output ──────────────────────────────────────────────────
        if cmd_sentinel in cmd_raw:
            cmd_body = _strip_ansi(cmd_raw.split(cmd_sentinel)[0]).strip()
        else:
            cmd_body = _strip_ansi(cmd_raw).strip() + "\n[WARNING: timed out]"

        # Extract exit code line
        exit_code_str = ""
        lines = cmd_body.split("\n")
        filtered = []
        for line in lines:
            if line.startswith("EXIT_CODE:"):
                exit_code_str = line
            else:
                filtered.append(line)
        cmd_body = "\n".join(filtered).strip()

        parts = []
        if prep_clean:
            parts.append(f"[prep -l {prep_course}]\n{prep_clean}")
        parts.append(f"[command output]\n{cmd_body}")
        if exit_code_str:
            parts.append(f"[{exit_code_str}]")
        return "\n\n".join(parts)

    except Exception as exc:
        return f"ERROR (SSH PTY): {exc}"


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
            time.sleep(0.5)
        except Exception:
            pass

        sftp.put(local_full, remote_path)
        sftp.close()
        ssh.close()
        return f"OK: Uploaded '{local_path}' → {remote_path}"
    except Exception as exc:
        return f"ERROR (upload): {exc}"


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
    except Exception as exc:
        return f"ERROR (download): {exc}"
