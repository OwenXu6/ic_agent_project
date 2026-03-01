# IC Design Automation AI Agent

An autonomous AI agent that drives a complete **RTL-to-GDSII** chip design flow — from Verilog RTL all the way through synthesis and physical place-and-route — without human intervention, powered by the **Claude API (Tool Use)**.

---

## Overview

This project implements an agentic loop using Anthropic's Claude API. The agent autonomously:
1. Writes and modifies Verilog RTL designs
2. Runs **Synopsys Design Compiler** synthesis on a remote EDA server
3. Runs **Cadence Innovus 21** place-and-route (floorplan → power → placement → CTS → routing → signoff)
4. Downloads and parses QoR reports (timing, power, area, DRC)
5. Iteratively fixes errors in TCL scripts until the flow completes

All EDA jobs run on **UCSD ieng6-ece-09** (ECE dedicated node) via SSH automation.

---

## Results

### 4-bit Ripple Carry Adder — TSMC 65nm GP

| Stage | Metric | Value |
|-------|--------|-------|
| DC Synthesis | WNS | **+0.21 ns** ✅ |
| DC Synthesis | Cell Area | **48.6 µm²** |
| DC Synthesis | Leakage Power | **193.6 nW** |
| Innovus P&R | Post-route Slack | **+0.138 ns** ✅ |
| Innovus P&R | DRC Violations | **0** ✅ |

### 8-bit ALU — TSMC 65nm GP @ 200 MHz

| Stage | Metric | Value |
|-------|--------|-------|
| DC Synthesis | WNS | **+1.81 ns** ✅ |
| DC Synthesis | Cell Area | **331.6 µm²** |
| DC Synthesis | Leakage Power | **573.7 nW** |
| Innovus P&R | Timing Closure | **MET** ✅ |
| Innovus P&R | DRC Violations | **0** ✅ |

---

## Architecture

```
User Prompt
    │
    ▼
agent.py  ──── Claude claude-opus-4-6 (streaming + tool_use)
    │                   │
    │         selects tool ──► tools/__init__.py (dispatcher)
    │
    ├── write_file / read_file / list_files   (local file I/O)
    ├── run_local_command                     (iverilog, git, etc.)
    ├── sync_to_remote                        (one-shot project upload via SFTP)
    ├── run_remote_command                    (SSH → EDA server)
    └── upload_to_remote / download_from_remote
    │
    ▼
ieng6-ece-09.ucsd.edu  (Synopsys DC + Cadence Innovus 21.1)
```

### Key Design Decisions

| Problem | Solution |
|---------|----------|
| SSH non-login shell can't `module load` EDA tools | Write commands as `bash --login` temp scripts |
| Claude API 30k token/min rate limit | Exponential-backoff retry (up to 6 attempts) |
| DC `compile_ultra` takes 10+ min | Configurable `timeout` param on `_run_remote_command` |
| Innovus 21 API breaks (e.g., `create_floorplan` → wrong command) | Iterative TCL debugging; use EDI-compatible commands (`floorPlan`, `routeDesign`, `ccopt_design`) |

---

## Full ASIC Flow (Automated)

```
RTL (Verilog)
  └─► DC Synthesis (dc_shell)
        ├── Library setup (TSMC 65nm GP .db files)
        ├── compile_ultra -no_autoungroup
        └── Gate-level netlist + SDC
              └─► Innovus 21 P&R
                    ├── MMMC setup (init_mmmc_file)
                    ├── init_design
                    ├── floorPlan -site core
                    ├── Power planning (globalNetConnect, addRing, addStripe, sroute)
                    ├── place_design
                    ├── CTS (ccopt_design)        ← sequential designs only
                    ├── routeDesign
                    ├── optDesign -postRoute
                    ├── verify_drc / verify_connectivity
                    └── defOut / saveNetlist
```

---

## Project Structure

```
ic_agent/
├── agent.py                          # Main agentic loop
├── config.py                         # SSH credentials, model settings
├── tools/
│   ├── __init__.py                   # Tool dispatcher
│   ├── file_tools.py                 # write_file, read_file, list_files
│   ├── command_tools.py              # run_local_command
│   └── remote_tools.py              # SSH tools (run, upload, download, sync)
├── designs/
│   ├── full_adder.v
│   ├── ripple_carry_adder_4bit.v
│   ├── ripple_carry_adder_4bit_synth.v   # Gate-level netlist (DC output)
│   ├── alu_8bit.v
│   └── alu_8bit_synth.v
├── scripts/
│   ├── dc_synthesis.tcl              # Synopsys DC (4-bit adder)
│   ├── dc_synthesis_alu.tcl          # Synopsys DC (8-bit ALU)
│   ├── innovus_pnr.tcl               # Cadence Innovus P&R (4-bit adder)
│   ├── innovus_pnr_alu.tcl           # Cadence Innovus P&R (8-bit ALU)
│   ├── constraints.sdc
│   ├── constraints_alu.sdc
│   └── constraints_*_synth.sdc
├── results/
│   ├── synth/                        # 4-bit adder synthesis reports
│   ├── synth_alu/                    # 8-bit ALU synthesis reports
│   ├── innovus/                      # 4-bit adder P&R results + DEF
│   └── innovus_alu/                  # 8-bit ALU P&R results + DEF
└── tb/
    ├── ripple_carry_adder_4bit_tb.v
    └── alu_8bit_tb.v
```

---

## Setup

### Requirements

```bash
pip install anthropic paramiko
```

### Configuration

Edit `config.py`:

```python
REMOTE_HOST      = "your-eda-server.edu"
REMOTE_USER      = "your_username"
REMOTE_PASSWORD  = "your_password"       # or use REMOTE_KEY for SSH key auth
REMOTE_WORK_DIR  = "/path/to/remote/ic_agent"
REMOTE_PREP_COURSE = "ECE260B_WI26_A00" # ACMS module group for EDA tools
MODEL            = "claude-opus-4-6"
MAX_AGENT_TURNS  = 80
```

### Run

```bash
cd "ic agent"
python3 agent.py
```

The agent will prompt for a task description, then autonomously execute the full design flow.

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| LLM | Anthropic Claude claude-opus-4-6 (streaming, tool use) |
| Synthesis | Synopsys Design Compiler 2015.06 |
| P&R | Cadence Innovus 21.10-p004_1 |
| PDK | TSMC 65nm GP (`tcbn65gplus` HVT/LVT, 8-layer metal) |
| SSH | Python `paramiko` — `bash --login` temp-script injection |
| Language | Python 3.9+ |

---

## 中文说明

本项目是一个基于 **Claude API（Tool Use）** 的 AI Agent，能够自动完成从 RTL 到 GDSII 的完整芯片设计流程，无需人工干预。

Agent 通过 7 个自定义工具，自主完成以下任务：
- 编写/修改 Verilog RTL 设计
- 在远程 EDA 服务器（UCSD ieng6-ece-09）上运行 Synopsys DC 综合
- 运行 Cadence Innovus 21 物理布局布线（布图规划 → 电源规划 → 布局 → CTS → 布线 → 签核）
- 下载并解析 QoR 报告（时序/功耗/面积/DRC）
- 自动迭代修复 TCL 脚本错误

**最终成果**：在 TSMC 65nm GP 工艺下完成两个设计的完整 RTL-to-GDSII 流程：
- 4-bit 波纹进位加法器：WNS +0.21 ns，面积 48.6 µm²，DRC violations = 0
- 8-bit ALU @ 200 MHz：WNS +1.81 ns，面积 331.6 µm²，DRC violations = 0

---

*Built with [Claude Code](https://claude.ai/claude-code)*
