# ==============================================================================
# Innovus Place & Route TCL Script
# Design: ripple_carry_adder_4bit
# Technology: TSMC 65nm GP (tcbn65gplus) — ECE260B PDK
# Author: IC Design Agent
#
# Prerequisites:
#   1. Run synthesis first (dc_synthesis.tcl) to produce the gate-level netlist.
#   2. Run with EDA tools loaded:
#        prep -l ECE260B_WI26_A00
#        cd ~/ic_agent
#        innovus -batch -source scripts/innovus_pnr.tcl
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 0: Design Parameters — paths auto-discovered from ECE260B PDK
# ------------------------------------------------------------------------------
set DESIGN_NAME  "ripple_carry_adder_4bit"
set NETLIST_FILE "designs/ripple_carry_adder_4bit_synth.v"   ;# post-synthesis gate netlist
set SDC_FILE     "scripts/constraints.sdc"
set OUTPUT_DIR   "results/innovus"

# ECE260B PDK root (TSMC 65nm GP)
set PDK_DIR "/home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata"

# Auto-discover LEF files (tech LEF + cell LEF)
set LEF_FILES [glob -nocomplain ${PDK_DIR}/lef/*.lef]
if {[llength $LEF_FILES] == 0} {
    puts "ERROR: No LEF files found in ${PDK_DIR}/lef/"
    exit 1
}
puts "Found LEF files: $LEF_FILES"

# Auto-discover Liberty timing libs (worst-case corner)
set LIB_FILES [glob -nocomplain ${PDK_DIR}/lib/*wc*.lib]
if {[llength $LIB_FILES] == 0} {
    # Fall back to all .lib files
    set LIB_FILES [glob -nocomplain ${PDK_DIR}/lib/*.lib]
}
if {[llength $LIB_FILES] == 0} {
    puts "ERROR: No Liberty (.lib) files found in ${PDK_DIR}/lib/"
    exit 1
}
puts "Found Liberty files: $LIB_FILES"

# Power/ground net names (TSMC 65nm convention)
set POWER_NET  "VDD"
set GROUND_NET "VSS"

file mkdir $OUTPUT_DIR

# ------------------------------------------------------------------------------
# Step 1: Read Design Data
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 1: Reading Design Data"
puts "========================================"

# Read physical libraries (LEF)
read_physical -lef $LEF_FILES

# Read timing libraries
read_timing_library $LIB_FILES

# Read the synthesized gate-level Verilog netlist
read_netlist $NETLIST_FILE

# Initialize design
init_design

# Read timing constraints
read_sdc $SDC_FILE

# ------------------------------------------------------------------------------
# Step 2: Floorplan
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 2: Floorplanning"
puts "========================================"

# Small 4-bit adder: 70% utilization, 1:1 aspect ratio, 5 µm margins
create_floorplan \
    -core_utilization    0.70 \
    -core_aspect_ratio   1.0  \
    -core_margins_by     die  \
    -left_io2core        5.0  \
    -right_io2core       5.0  \
    -top_io2core         5.0  \
    -bottom_io2core      5.0

check_floorplan

# ------------------------------------------------------------------------------
# Step 3: Power Planning
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 3: Power Planning"
puts "========================================"

connect_global_net $POWER_NET  -type pg_pin -pin_base_name $POWER_NET  -inst_base_name *
connect_global_net $GROUND_NET -type pg_pin -pin_base_name $GROUND_NET -inst_base_name *

# Power rings around core
add_rings \
    -nets        [list $POWER_NET $GROUND_NET] \
    -type        core_rings \
    -layer       {top metal3 bottom metal3 left metal4 right metal4} \
    -width       1.0 \
    -spacing     0.5 \
    -offset      0.5

# Horizontal power stripes on metal3
add_stripes \
    -nets              [list $POWER_NET $GROUND_NET] \
    -layer             metal3 \
    -direction         horizontal \
    -width             0.8 \
    -spacing           0.5 \
    -set_to_set_distance 20.0 \
    -start_from        bottom \
    -start_offset      5.0

route_special \
    -connect              {core_pin} \
    -layer_change_range   {metal1 metal4} \
    -block_pin_target     nearest_target \
    -allow_jogging        1 \
    -crossover_via_layer_range {metal1 metal4}

# ------------------------------------------------------------------------------
# Step 4: Placement
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 4: Placement"
puts "========================================"

place_design -effort high
check_place
report_summary -out_dir ${OUTPUT_DIR}/placement_reports

# ------------------------------------------------------------------------------
# Step 5: Clock Tree Synthesis (CTS)
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 5: Clock Tree Synthesis"
puts "========================================"

# This design is purely combinational — no clock tree needed.
puts "  [INFO] Skipping CTS — combinational-only design."

# For sequential designs, uncomment:
# create_clock_tree_spec -output ${OUTPUT_DIR}/cts_spec.tcl
# source ${OUTPUT_DIR}/cts_spec.tcl
# clock_design
# report_clock_tree -summary > ${OUTPUT_DIR}/cts_report.txt

# ------------------------------------------------------------------------------
# Step 6: Routing
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 6: Routing"
puts "========================================"

set_nanoroute_mode -quiet -route_with_timing_driven true
set_nanoroute_mode -quiet -route_with_si_driven     false
set_nanoroute_mode -quiet -drouteFixAntenna         true

route_global
route_detail -max_route_layer metal4

check_drc          -out_file ${OUTPUT_DIR}/drc_violations.rpt
verify_connectivity -report  ${OUTPUT_DIR}/connectivity.rpt

# ------------------------------------------------------------------------------
# Step 7: Post-Route Optimization & Timing
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 7: Post-Route Optimization"
puts "========================================"

opt_design -post_route -hold
opt_design -post_route -setup

report_timing   -max_paths 10 -net_delay_model > ${OUTPUT_DIR}/timing_report.txt
report_power                                   > ${OUTPUT_DIR}/power_report.txt
report_area                                    > ${OUTPUT_DIR}/area_report.txt

# ------------------------------------------------------------------------------
# Step 8: Signoff Checks
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 8: Signoff Checks"
puts "========================================"

verify_drc          -report ${OUTPUT_DIR}/final_drc.rpt
verify_connectivity -report ${OUTPUT_DIR}/final_connectivity.rpt
check_design -type all      > ${OUTPUT_DIR}/design_check.rpt

# ------------------------------------------------------------------------------
# Step 9: Export Results
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 9: Exporting Results"
puts "========================================"

save_design  ${OUTPUT_DIR}/${DESIGN_NAME}_final.enc

write_def    ${OUTPUT_DIR}/${DESIGN_NAME}_final.def

write_netlist ${OUTPUT_DIR}/${DESIGN_NAME}_postroute.v

write_sdf     ${OUTPUT_DIR}/${DESIGN_NAME}_postroute.sdf

write_spef    ${OUTPUT_DIR}/${DESIGN_NAME}_postroute.spef

# GDS export — requires a layer map file from the PDK
# Uncomment and set GDS_MAP_FILE if available:
# set GDS_MAP_FILE "${PDK_DIR}/gds_map.map"
# write_gds ${OUTPUT_DIR}/${DESIGN_NAME}.gds \
#     -map_file $GDS_MAP_FILE -unit 1000 -structure top

puts "========================================"
puts "  Place & Route COMPLETE"
puts "  Results saved to: ${OUTPUT_DIR}/"
puts "========================================"

exit
