# ==============================================================================
# Innovus Place & Route TCL Script
# Design: alu_8bit
# Technology: TSMC 65nm GP (tcbn65gplus) — ECE260B PDK
# Uses MMMC (Multi-Mode Multi-Corner) flow for Innovus v21
# ==============================================================================

set DESIGN_NAME  "alu_8bit"
set NETLIST_FILE "designs/alu_8bit_synth.v"
set SDC_FILE     "scripts/constraints_alu_synth.sdc"
set OUTPUT_DIR   "results/innovus_alu"

set PDK_DIR "/home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata"

# Auto-discover LEF files
set LEF_FILES [glob -nocomplain ${PDK_DIR}/lef/*.lef]
if {[llength $LEF_FILES] == 0} {
    puts "ERROR: No LEF files found in ${PDK_DIR}/lef/"
    exit 1
}
puts "Found LEF files: $LEF_FILES"

# Auto-discover Liberty timing libs (worst-case corner)
set LIB_FILES [glob -nocomplain ${PDK_DIR}/lib/*wc*.lib]
if {[llength $LIB_FILES] == 0} {
    set LIB_FILES [glob -nocomplain ${PDK_DIR}/lib/*.lib]
}
if {[llength $LIB_FILES] == 0} {
    puts "ERROR: No Liberty (.lib) files found in ${PDK_DIR}/lib/"
    exit 1
}
puts "Found Liberty files: $LIB_FILES"

set POWER_NET  "VDD"
set GROUND_NET "VSS"

file mkdir $OUTPUT_DIR

# ------------------------------------------------------------------------------
# Step 1: Read Design Data (MMMC Flow)
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 1: Reading Design Data (MMMC)"
puts "========================================"

set mmmc_path "/tmp/ic_agent_alu_mmmc_viewdef.tcl"
set fp [open $mmmc_path w]
puts $fp "create_library_set -name wc_libs -timing {$LIB_FILES}"
puts $fp "create_constraint_mode -name func_mode -sdc_files {$SDC_FILE}"
puts $fp "create_delay_corner -name wc_corner -library_set {wc_libs}"
puts $fp "create_analysis_view -name wc_view -constraint_mode func_mode -delay_corner wc_corner"
puts $fp "set_analysis_view -setup {wc_view} -hold {wc_view}"
close $fp
puts "Written MMMC view definition to $mmmc_path"

set init_lef_file  $LEF_FILES
set init_mmmc_file $mmmc_path
set init_verilog   $NETLIST_FILE
set init_top_cell  $DESIGN_NAME
set init_pwr_net   $POWER_NET
set init_gnd_net   $GROUND_NET

init_design

# ------------------------------------------------------------------------------
# Step 2: Floorplan
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 2: Floorplanning"
puts "========================================"

# floorPlan: -r aspectRatio coreUtilization leftMargin bottomMargin rightMargin topMargin
floorPlan -site core -r 1.0 0.60 5.0 5.0 5.0 5.0

# ------------------------------------------------------------------------------
# Step 3: Power Planning
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 3: Power Planning"
puts "========================================"

globalNetConnect $POWER_NET  -type pgpin -pin $POWER_NET  -inst * -override
globalNetConnect $GROUND_NET -type pgpin -pin $GROUND_NET -inst * -override

addRing \
    -nets        [list $POWER_NET $GROUND_NET] \
    -type        core_rings \
    -layer       {top M3 bottom M3 left M4 right M4} \
    -width       1.0 \
    -spacing     0.5 \
    -offset      0.5

addStripe \
    -nets              [list $POWER_NET $GROUND_NET] \
    -layer             M3 \
    -direction         horizontal \
    -width             0.8 \
    -spacing           0.5 \
    -set_to_set_distance 20.0 \
    -start_from        bottom \
    -start_offset      5.0

sroute \
    -connect              {corePin} \
    -layerChangeRange     {M1 M4} \
    -blockPinTarget       nearestTarget \
    -allowJogging         1 \
    -crossoverViaLayerRange {M1 M4}

# ------------------------------------------------------------------------------
# Step 4: Placement
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 4: Placement"
puts "========================================"

place_design

# ------------------------------------------------------------------------------
# Step 5: CTS
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 5: Clock Tree Synthesis"
puts "========================================"

create_ccopt_clock_tree_spec
ccopt_design

# ------------------------------------------------------------------------------
# Step 6: Routing
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 6: Routing"
puts "========================================"

setNanoRouteMode -routeWithTimingDriven 1
setNanoRouteMode -routeWithSiDriven   0

routeDesign

verify_drc          -report ${OUTPUT_DIR}/drc_violations.rpt
verify_connectivity -report ${OUTPUT_DIR}/connectivity.rpt

# ------------------------------------------------------------------------------
# Step 7: Post-Route Optimization & Reports
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 7: Post-Route Optimization"
puts "========================================"

setAnalysisMode -analysisType onChipVariation
optDesign -postRoute

report_timing > ${OUTPUT_DIR}/timing_report.txt
report_power  -outfile ${OUTPUT_DIR}/power_report.txt
summaryReport -noHtml   -outfile ${OUTPUT_DIR}/area_report.txt

# ------------------------------------------------------------------------------
# Step 8: Signoff Checks
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 8: Signoff Checks"
puts "========================================"

verify_drc          -report ${OUTPUT_DIR}/final_drc.rpt
verify_connectivity -report ${OUTPUT_DIR}/final_connectivity.rpt

# ------------------------------------------------------------------------------
# Step 9: Export Results
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 9: Exporting Results"
puts "========================================"

defOut    ${OUTPUT_DIR}/${DESIGN_NAME}_final.def
saveNetlist ${OUTPUT_DIR}/${DESIGN_NAME}_postroute.v

puts "========================================"
puts "  Place & Route COMPLETE"
puts "  Results saved to: ${OUTPUT_DIR}/"
puts "========================================"

exit
