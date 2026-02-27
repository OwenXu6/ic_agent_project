import os

# ── Local project paths ──────────────────────────────────────────────────────
WORK_DIR = os.path.dirname(os.path.abspath(__file__))

# ── GitHub ───────────────────────────────────────────────────────────────────
GITHUB_REPO = "git@github.com:YOUR_USERNAME/ic_agent_project.git"

# ── Remote EDA Server (UCSD Linux Cloud / ieng6) ────────────────────────────
# Copy this file to config.py and fill in your credentials.
# config.py is in .gitignore and will never be committed.
REMOTE_HOST = "ieng6.ucsd.edu"       # or your actual server hostname
REMOTE_USER = "YOUR_USERNAME"         # your UCSD account (e.g. cs260xxx)
REMOTE_PASSWORD = "YOUR_PASSWORD"     # leave empty if using SSH key
REMOTE_KEY  = ""                      # path to SSH key, or leave empty for password auth
REMOTE_WORK_DIR = "/home/linux/ieng6/YOUR_USERNAME/ic_agent"
REMOTE_PREP_COURSE = "ECE260B_WI26_A00"  # course label passed to `prep -l <COURSE>` on ieng6

# ── Claude model ─────────────────────────────────────────────────────────────
MODEL = "claude-opus-4-6"

# ── Safety limits ────────────────────────────────────────────────────────────
MAX_AGENT_TURNS = 40
