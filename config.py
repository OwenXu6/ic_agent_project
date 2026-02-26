import os

# ── Local project paths ──────────────────────────────────────────────────────
WORK_DIR = os.path.dirname(os.path.abspath(__file__))

# ── GitHub ───────────────────────────────────────────────────────────────────
# Set this to your GitHub repo remote URL, e.g.:
#   https://github.com/username/ic-agent.git
# The agent will use 'git push' once the repo is initialized locally.
GITHUB_REPO = os.environ.get("GITHUB_REPO", "")

# ── Remote EDA Server (school server with Innovus) ───────────────────────────
# Fill these in before using remote tools.
# Recommended: use SSH key auth (no password prompts).
#
# Example:
#   REMOTE_HOST = "eda.school.edu"
#   REMOTE_USER = "s12345678"
#   REMOTE_KEY  = os.path.expanduser("~/.ssh/id_rsa")
#   REMOTE_WORK_DIR = "/home/s12345678/ic_agent"

REMOTE_HOST = os.environ.get("REMOTE_HOST", "")        # e.g. "eda.yourschool.edu"
REMOTE_USER = os.environ.get("REMOTE_USER", "")        # your login username
REMOTE_KEY  = os.environ.get("REMOTE_KEY",
              os.path.expanduser("~/.ssh/id_rsa"))      # SSH private key
REMOTE_WORK_DIR = os.environ.get("REMOTE_WORK_DIR", "")  # remote working dir

# ── Claude model ─────────────────────────────────────────────────────────────
MODEL = "claude-opus-4-6"

# ── Safety limits ────────────────────────────────────────────────────────────
MAX_AGENT_TURNS = 40   # maximum tool-call rounds before stopping
