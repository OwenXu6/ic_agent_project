# ==============================================================================
# Design Compiler Synthesis Script
# Design: ripple_carry_adder_4bit
# Technology: TSMC 65nm GP (tcbn65gplus) — ECE260B PDK
# Author: IC Design Agent
#
# Prerequisites:
#   prep -l ECE260B_WI26_A00
#   cd ~/ic_agent
#   dc_shell -f scripts/dc_synthesis.tcl | tee results/synth/dc_run.log
#
# Outputs:
#   designs/ripple_carry_adder_4bit_synth.v  — gate-level netlist for Innovus
#   scripts/constraints_synth.sdc            — updated SDC
#   results/synth/*.rpt                      — timing/area/power/QoR reports
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 0: Setup
# ------------------------------------------------------------------------------
set DESIGN_NAME "ripple_carry_adder_4bit"

# RTL source files (order matters: sub-modules first)
set RTL_FILES {
    designs/full_adder.v
    designs/ripple_carry_adder_4bit.v
}

set SDC_FILE   "scripts/constraints.sdc"
set OUTPUT_DIR "results/synth"

# PDK library directory
set DB_DIR "/home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db"

# ------------------------------------------------------------------------------
# Step 1: Configure technology libraries
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 1: Setting up libraries"
puts "========================================"

# Prefer worst-case corner for conservative synthesis
set wc_libs [glob -nocomplain ${DB_DIR}/*wc*.db]
if {[llength $wc_libs] == 0} {
    puts "WARNING: No worst-case .db files found; falling back to all .db files"
    set wc_libs [glob -nocomplain ${DB_DIR}/*.db]
}
if {[llength $wc_libs] == 0} {
    puts "ERROR: No .db library files found in ${DB_DIR}"
    exit 1
}

set target_library $wc_libs
set link_library   [concat * $target_library]
puts "Using libraries: $wc_libs"

# Create output directory
file mkdir $OUTPUT_DIR
file mkdir results

# ------------------------------------------------------------------------------
# Step 2: Read RTL
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 2: Reading RTL"
puts "========================================"

foreach f $RTL_FILES {
    if {![file exists $f]} {
        puts "ERROR: RTL file not found: $f"
        exit 1
    }
    analyze -library work -format verilog $f
}
elaborate $DESIGN_NAME

# ------------------------------------------------------------------------------
# Step 3: Design check and linking
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 3: Linking and checking design"
puts "========================================"

current_design $DESIGN_NAME
link
uniquify

set check_result [check_design]
redirect ${OUTPUT_DIR}/check_design.rpt { check_design }
puts "check_design written to ${OUTPUT_DIR}/check_design.rpt"

# ------------------------------------------------------------------------------
# Step 4: Apply timing constraints
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 4: Applying constraints"
puts "========================================"

# Start from clean state
reset_design

# Re-elaborate for clean constraint application
elaborate $DESIGN_NAME
current_design $DESIGN_NAME
link

# Apply SDC timing constraints
source $SDC_FILE
puts "Applied constraints from $SDC_FILE"

# Set input/output delays relative to the virtual clock
# (adder is purely combinational; using a virtual 10ns clock)
set_input_delay  2.0 -clock virtual_clk [all_inputs]
set_output_delay 2.0 -clock virtual_clk [all_outputs]

# Max fanout and transition
set_max_fanout  8   [current_design]
set_max_transition 0.5 [current_design]

# ------------------------------------------------------------------------------
# Step 5: Compile (synthesis)
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 5: Synthesis"
puts "========================================"

# compile_ultra: aggressive timing-driven synthesis
# -no_autoungroup: keep hierarchy intact for easier debug
# -timing_high_effort_script: extra optimization passes
compile_ultra -no_autoungroup -timing_high_effort_script

# ------------------------------------------------------------------------------
# Step 6: Generate reports
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 6: Reports"
puts "========================================"

redirect ${OUTPUT_DIR}/timing.rpt     { report_timing -max_paths 20 -input_pins }
redirect ${OUTPUT_DIR}/area.rpt       { report_area   -hierarchy }
redirect ${OUTPUT_DIR}/power.rpt      { report_power }
redirect ${OUTPUT_DIR}/qor.rpt        { report_qor }
redirect ${OUTPUT_DIR}/constraints.rpt { report_constraint -all_violators }

# Print WNS summary inline for agent to parse easily
puts "-------- TIMING SUMMARY --------"
set worst [get_attribute [get_timing_paths -max_paths 1 -slack_lesser_than 0] slack]
if {[llength $worst] > 0} {
    puts "TIMING VIOLATIONS DETECTED. WNS = $worst ns"
    puts "See ${OUTPUT_DIR}/timing.rpt for details."
} else {
    puts "TIMING CLEAN: No setup violations found."
}
puts "---------------------------------"

# ------------------------------------------------------------------------------
# Step 7: Write outputs
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 7: Writing outputs"
puts "========================================"

# Gate-level Verilog netlist (input to Innovus)
write -format verilog -hierarchy \
    -output designs/${DESIGN_NAME}_synth.v
puts "Gate-level netlist: designs/${DESIGN_NAME}_synth.v"

# Updated SDC (timing constraints for P&R)
write_sdc -nosplit scripts/constraints_synth.sdc
puts "Updated SDC: scripts/constraints_synth.sdc"

# DSPF/SDF stubs — not needed at this stage
# write_sdf ${OUTPUT_DIR}/${DESIGN_NAME}_synth.sdf

puts "========================================"
puts "  SYNTHESIS COMPLETE — check ${OUTPUT_DIR}/ for reports"
puts "========================================"

exit
