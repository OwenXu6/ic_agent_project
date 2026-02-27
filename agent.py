"""
IC Design Agent
===============
An AI agent powered by Claude that autonomously designs hardware (Verilog),
runs EDA flows (simulation, place-and-route via Innovus), and pushes results
to GitHub.

Usage:
    python agent.py
    Then type your task, e.g.:
      "Design a 4-bit ripple carry adder in Verilog, write a testbench,
       simulate it with iverilog, and commit to GitHub."
"""

import sys
import json
import os
import anthropic
import config
from tools import ALL_TOOLS, execute_tool

# Load .env if present (provides ANTHROPIC_API_KEY without polluting git)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    # Fallback: parse .env manually
    _env_path = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(_env_path):
        with open(_env_path) as _f:
            for _line in _f:
                _line = _line.strip()
                if _line and not _line.startswith("#") and "=" in _line:
                    _k, _v = _line.split("=", 1)
                    os.environ.setdefault(_k.strip(), _v.strip())

SYSTEM_PROMPT = """You are an expert IC design engineer and EDA automation specialist.
You help users design digital hardware using Verilog/SystemVerilog, run simulations,
and orchestrate complete RTL-to-GDSII flows (synthesis → place-and-route → signoff).

════════════════════════════════════════
  STANDARD FLOW (RTL → GDSII)
════════════════════════════════════════
1. Write clean, synthesizable Verilog RTL  → designs/
2. Write self-checking testbenches         → tb/
3. Simulate locally: iverilog + vvp        (verify function before silicon)
4. Upload RTL + TCL to remote server
5. Run DC synthesis:
       dc_shell -f scripts/dc_synthesis.tcl | tee results/synth/dc_run.log
   → produces: designs/<name>_synth.v  (gate-level netlist for Innovus)
               scripts/constraints_synth.sdc
6. Run Innovus P&R:
       innovus -batch -source scripts/innovus_pnr.tcl
   → produces: results/innovus/*.rpt, *.def, *.gds
7. Download reports to local results/
8. Commit everything to GitHub

════════════════════════════════════════
  EDA ERROR-HANDLING STRATEGY
════════════════════════════════════════
EDA tools rarely succeed on the first run for non-trivial designs.
Always apply this iterative debug loop:

  READ OUTPUT → IDENTIFY ERROR CLASS → APPLY FIX → RERUN → CHECK AGAIN

─── Synthesis errors (dc_shell) ────────────────────────────────────────────
• Unresolved reference / "cannot find design X":
    Check RTL_FILES list in TCL includes all modules. Fix and rerun.
• Setup timing violation (WNS < 0):
    1. Read results/synth/timing.rpt — find critical path
    2. If WNS > -0.5 ns: add `set_optimize_registers true` + recompile
    3. If WNS > -1 ns: relax clock period in constraints.sdc by 10%
    4. If WNS > -2 ns: consider pipelining the critical path in RTL
    5. Extreme: restructure logic (e.g., carry-lookahead instead of ripple)
• Area too large: use `compile -area_effort high` instead of compile_ultra
• Power too high: enable clock gating (`set_clock_gating_style`)

─── P&R errors (Innovus) ───────────────────────────────────────────────────
• "Cannot read netlist" / missing file:
    Verify synthesis step produced designs/<name>_synth.v. Run synthesis first.
• Floorplan congestion / >90% utilization:
    Lower `core_utilization` from 0.70 → 0.55 in innovus_pnr.tcl. Rerun.
• DRC violations after routing:
    1. Read results/innovus/drc_violations.rpt
    2. For spacing/width: adjust routing rules (set_db nanoroute rules)
    3. For antenna: add antenna diodes (add_antenna_diode_cells)
    4. For unrouted nets: increase routing layers (max_route_layer metal5+)
• Timing not closed post-route:
    1. Read results/innovus/timing_report.txt — find violating paths
    2. Run `opt_design -post_route -hold -setup` again
    3. If still failing: go back to synthesis with tighter target (add margin)
• Memory / license errors:
    Note the error and report to user — cannot fix autonomously.

─── General EDA debugging rules ────────────────────────────────────────────
• After ANY failed run: use read_file to inspect the log before retrying
• Never blindly retry the same command — diagnose first
• For complex designs, plan a fix before making it: "I see WNS = -1.2 ns on
  the carry chain. I will relax the clock to 12 ns and recompile."
• Max retry attempts per stage: 3. After 3 failures, report to user with
  detailed analysis of what was tried and what the remaining errors are.
• Always check QoR (quality-of-results): timing, area, power are all goals

════════════════════════════════════════
  DESIGN CONVENTIONS
════════════════════════════════════════
- Module names: `adder_4bit`, `alu_8bit`, `fifo_sync_16x8`, etc.
- Testbenches: exhaustive for small designs, directed + random for large
- Commit messages: describe what was designed AND the QoR results
  e.g. "feat: 8-bit ALU synthesis — WNS=+0.3ns, area=450 µm², power=1.2mW"
"""


def run_agent(task: str):
    client = anthropic.Anthropic()
    messages = [{"role": "user", "content": task}]

    print(f"\n{'='*60}")
    print(f"Task: {task}")
    print(f"{'='*60}\n")

    for turn in range(config.MAX_AGENT_TURNS):
        # Call Claude with streaming, retrying on rate-limit errors
        for attempt in range(6):
            try:
                with client.messages.stream(
                    model=config.MODEL,
                    max_tokens=8192,
                    thinking={"type": "adaptive"},
                    system=SYSTEM_PROMPT,
                    tools=ALL_TOOLS,
                    messages=messages,
                ) as stream:
                    response = stream.get_final_message()
                break  # success
            except anthropic.RateLimitError as e:
                wait = 30 * (attempt + 1)
                print(f"\n[rate-limit] Hit API rate limit, retrying in {wait}s... ({e})")
                import time; time.sleep(wait)
        else:
            raise RuntimeError("Exceeded rate-limit retry budget")

        # Show assistant text output
        for block in response.content:
            if block.type == "thinking":
                print(f"\n[thinking] {block.thinking[:200]}{'...' if len(block.thinking) > 200 else ''}")
            elif block.type == "text":
                print(f"\n[claude] {block.text}")

        # Done when Claude stops calling tools
        if response.stop_reason == "end_turn":
            print(f"\n{'='*60}")
            print("Task completed.")
            print(f"{'='*60}\n")
            break

        # Handle tool calls
        if response.stop_reason == "tool_use":
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    print(f"\n[tool] {block.name}({_fmt_input(block.input)})")
                    result = execute_tool(block.name, block.input)
                    # Truncate long outputs for display
                    display = result if len(result) <= 500 else result[:500] + "\n...(truncated)"
                    print(f"[result] {display}")
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": result
                    })

            # Append assistant turn and tool results
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user", "content": tool_results})
        else:
            # Unexpected stop reason
            print(f"[warn] Unexpected stop_reason: {response.stop_reason}")
            break
    else:
        print(f"\n[warn] Reached maximum turns ({config.MAX_AGENT_TURNS}). Stopping.")


def _fmt_input(inp: dict) -> str:
    """Format tool input for concise display."""
    parts = []
    for k, v in inp.items():
        val = str(v)
        if len(val) > 80:
            val = val[:80] + "..."
        parts.append(f"{k}={val!r}")
    return ", ".join(parts)


def main():
    print("IC Design Agent — powered by Claude")
    print("Type your hardware design task and press Enter.")
    print("Examples:")
    print("  - Design a 4-bit ripple carry adder and simulate it")
    print("  - Design an 8-bit ALU with add/sub/and/or operations")
    print("  - Design a D flip-flop with async reset")
    print()

    if len(sys.argv) > 1:
        task = " ".join(sys.argv[1:])
    else:
        try:
            task = input("Task> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nExiting.")
            return

    if not task:
        print("No task provided. Exiting.")
        return

    run_agent(task)


if __name__ == "__main__":
    main()
