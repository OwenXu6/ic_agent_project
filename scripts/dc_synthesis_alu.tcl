# ==============================================================================
# Design Compiler Synthesis Script
# Design: alu_8bit
# Technology: TSMC 65nm GP (tcbn65gplus) — ECE260B PDK
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 0: Setup
# ------------------------------------------------------------------------------
set DESIGN_NAME "alu_8bit"
set RTL_FILES   { designs/alu_8bit.v }
set SDC_FILE    "scripts/constraints_alu.sdc"
set OUTPUT_DIR  "results/synth_alu"

set PDK_DIR "/home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db"

# ------------------------------------------------------------------------------
# Step 1: Configure technology libraries
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 1: Setting up libraries"
puts "========================================"

set wc_libs [glob -nocomplain ${PDK_DIR}/*wc*.db]
if {[llength $wc_libs] == 0} {
    puts "WARNING: No worst-case .db files found; falling back to all .db files"
    set wc_libs [glob -nocomplain ${PDK_DIR}/*.db]
}
if {[llength $wc_libs] == 0} {
    puts "ERROR: No .db library files found in ${PDK_DIR}"
    exit 1
}

set target_library $wc_libs
set link_library   [concat * $target_library]
puts "Using libraries: $wc_libs"

file mkdir $OUTPUT_DIR

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
# Step 3: Link and check
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 3: Linking and checking design"
puts "========================================"

current_design $DESIGN_NAME
link
uniquify

redirect ${OUTPUT_DIR}/check_design.rpt { check_design }
puts "check_design written to ${OUTPUT_DIR}/check_design.rpt"

# ------------------------------------------------------------------------------
# Step 4: Apply timing constraints
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 4: Applying constraints"
puts "========================================"

source $SDC_FILE
puts "Applied constraints from $SDC_FILE"

set_max_fanout     8   [current_design]
set_max_transition 0.5 [current_design]

# ------------------------------------------------------------------------------
# Step 5: Compile (synthesis)
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 5: Synthesis"
puts "========================================"

compile_ultra -no_autoungroup

# ------------------------------------------------------------------------------
# Step 6: Generate reports
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 6: Reports"
puts "========================================"

redirect ${OUTPUT_DIR}/timing.rpt      { report_timing -max_paths 20 -input_pins }
redirect ${OUTPUT_DIR}/area.rpt        { report_area   -hierarchy }
redirect ${OUTPUT_DIR}/power.rpt       { report_power }
redirect ${OUTPUT_DIR}/qor.rpt         { report_qor }
redirect ${OUTPUT_DIR}/constraints.rpt { report_constraint -all_violators }

puts "-------- TIMING SUMMARY --------"
report_timing -max_paths 1
puts "---------------------------------"

# ------------------------------------------------------------------------------
# Step 7: Write outputs
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 7: Writing outputs"
puts "========================================"

write -format verilog -hierarchy \
    -output designs/${DESIGN_NAME}_synth.v
puts "Gate-level netlist: designs/${DESIGN_NAME}_synth.v"

write_sdc -nosplit scripts/constraints_alu_synth.sdc
puts "Updated SDC: scripts/constraints_alu_synth.sdc"

puts "========================================"
puts "  SYNTHESIS COMPLETE — check ${OUTPUT_DIR}/ for reports"
puts "========================================"

exit
