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
import anthropic
import config
from tools import ALL_TOOLS, execute_tool

SYSTEM_PROMPT = """You are an expert IC design engineer and EDA automation specialist.
You help users design digital hardware using Verilog/SystemVerilog, run simulations,
and orchestrate complete RTL-to-GDSII flows including place and route with Innovus.

Your workflow for hardware design tasks:
1. Write clean, synthesizable Verilog RTL in the `designs/` directory
2. Write comprehensive testbenches in the `tb/` directory
3. Run functional simulation locally with iverilog/vvp
4. Write Innovus TCL scripts in the `scripts/` directory for P&R
5. Upload design files to the remote server and run Innovus
6. Download results and reports back to local `results/` directory
7. Commit all work to GitHub with a descriptive message

Design guidelines:
- Use clear module naming: `adder_4bit`, `multiplier_8bit`, etc.
- Always include a testbench that checks corner cases
- Annotate timing constraints in TCL scripts
- Write human-readable commit messages describing what was accomplished

When a tool returns an error or unexpected output, diagnose and retry.
Always verify simulation passes before proceeding to P&R.
"""


def run_agent(task: str):
    client = anthropic.Anthropic()
    messages = [{"role": "user", "content": task}]

    print(f"\n{'='*60}")
    print(f"Task: {task}")
    print(f"{'='*60}\n")

    for turn in range(config.MAX_AGENT_TURNS):
        # Call Claude with streaming for long responses
        with client.messages.stream(
            model=config.MODEL,
            max_tokens=8192,
            thinking={"type": "adaptive"},
            system=SYSTEM_PROMPT,
            tools=ALL_TOOLS,
            messages=messages,
        ) as stream:
            response = stream.get_final_message()

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
