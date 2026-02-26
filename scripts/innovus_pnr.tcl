# ==============================================================================
# Innovus Place & Route TCL Script (Template)
# Design: ripple_carry_adder_4bit
# Technology: Generic 45nm (adjust library paths for your PDK)
# Author: IC Design Agent
#
# Usage: innovus -batch -source scripts/innovus_pnr.tcl
# ==============================================================================

# ------------------------------------------------------------------------------
# Step 0: Design Parameters (CUSTOMIZE THESE FOR YOUR ENVIRONMENT)
# ------------------------------------------------------------------------------
set DESIGN_NAME    "ripple_carry_adder_4bit"
set NETLIST_FILE   "designs/ripple_carry_adder_4bit_synth.v"   ;# Post-synthesis netlist
set SDC_FILE       "scripts/constraints.sdc"
set LEF_FILES      [list \
    "/path/to/tech.lef" \
    "/path/to/stdcell.lef" \
]
set LIB_FILES      [list \
    "/path/to/stdcell_typ.lib" \
]
set GDS_MAP_FILE   "/path/to/gds_map.map"
set POWER_NET      "VDD"
set GROUND_NET     "VSS"

# Output directory
set OUTPUT_DIR     "results/innovus"
file mkdir $OUTPUT_DIR

# ------------------------------------------------------------------------------
# Step 1: Read Design Data
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 1: Reading Design Data"
puts "========================================"

# Read physical libraries (LEF)
foreach lef $LEF_FILES {
    read_physical -lef $lef
}

# Read timing libraries
foreach lib $LIB_FILES {
    read_timing_library $lib
}

# Read the synthesized Verilog netlist
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

# Create a simple floorplan with aspect ratio 1.0 and 70% utilization
# For a small 4-bit adder, the die area will be very small
create_floorplan \
    -core_utilization 0.70 \
    -core_aspect_ratio 1.0 \
    -core_margins_by die \
    -left_io2core   5.0 \
    -right_io2core  5.0 \
    -top_io2core    5.0 \
    -bottom_io2core 5.0

# Verify floorplan
check_floorplan

# ------------------------------------------------------------------------------
# Step 3: Power Planning
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 3: Power Planning"
puts "========================================"

# Connect global power/ground nets
connect_global_net $POWER_NET  -type pg_pin -pin_base_name $POWER_NET -inst_base_name *
connect_global_net $GROUND_NET -type pg_pin -pin_base_name $GROUND_NET -inst_base_name *

# Add power rings around core
add_rings \
    -nets [list $POWER_NET $GROUND_NET] \
    -type core_rings \
    -layer {top metal3 bottom metal3 left metal4 right metal4} \
    -width 1.0 \
    -spacing 0.5 \
    -offset 0.5

# Add horizontal power stripes
add_stripes \
    -nets [list $POWER_NET $GROUND_NET] \
    -layer metal3 \
    -direction horizontal \
    -width 0.8 \
    -spacing 0.5 \
    -set_to_set_distance 20.0 \
    -start_from bottom \
    -start_offset 5.0

# Route special (power) nets
route_special \
    -connect {core_pin} \
    -layer_change_range {metal1 metal4} \
    -block_pin_target nearest_target \
    -allow_jogging 1 \
    -crossover_via_layer_range {metal1 metal4}

# ------------------------------------------------------------------------------
# Step 4: Placement
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 4: Placement"
puts "========================================"

# Run standard cell placement
place_design -effort high

# Check placement
check_place

# Report placement summary
report_summary -out_dir ${OUTPUT_DIR}/placement_reports

# ------------------------------------------------------------------------------
# Step 5: Clock Tree Synthesis (CTS)
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 5: Clock Tree Synthesis"
puts "========================================"

# NOTE: This design is purely combinational (no clock).
# CTS is included here as a template for sequential designs.
# Uncomment the following lines for designs with clocks:
#
# create_clock_tree_spec -output ${OUTPUT_DIR}/cts_spec.tcl
# source ${OUTPUT_DIR}/cts_spec.tcl
# clock_design
# report_clock_tree -summary > ${OUTPUT_DIR}/cts_report.txt

puts "  [INFO] Skipping CTS - design is purely combinational."

# ------------------------------------------------------------------------------
# Step 6: Routing
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 6: Routing"
puts "========================================"

# Set routing rules
set_nanoroute_mode -quiet -route_with_timing_driven true
set_nanoroute_mode -quiet -route_with_si_driven false
set_nanoroute_mode -quiet -drouteFixAntenna true

# Global route
route_global

# Detailed route
route_detail -max_route_layer metal4

# Check for DRC violations
check_drc -out_file ${OUTPUT_DIR}/drc_violations.rpt

# Verify connectivity
verify_connectivity -report ${OUTPUT_DIR}/connectivity.rpt

# ------------------------------------------------------------------------------
# Step 7: Timing Analysis & Optimization
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 7: Post-Route Optimization"
puts "========================================"

# Post-route optimization
opt_design -post_route -hold
opt_design -post_route -setup

# Report timing
report_timing -max_paths 10 -net_delay_model > ${OUTPUT_DIR}/timing_report.txt

# Report power
report_power > ${OUTPUT_DIR}/power_report.txt

# Report area
report_area  > ${OUTPUT_DIR}/area_report.txt

# ------------------------------------------------------------------------------
# Step 8: Signoff Checks
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 8: Signoff Checks"
puts "========================================"

# Final DRC check
verify_drc -report ${OUTPUT_DIR}/final_drc.rpt

# Final connectivity check
verify_connectivity -report ${OUTPUT_DIR}/final_connectivity.rpt

# Geometry check
check_design -type all > ${OUTPUT_DIR}/design_check.rpt

# ------------------------------------------------------------------------------
# Step 9: Export Results
# ------------------------------------------------------------------------------
puts "========================================"
puts "  Step 9: Exporting Results"
puts "========================================"

# Save design database
save_design ${OUTPUT_DIR}/${DESIGN_NAME}_final.enc

# Export DEF (Design Exchange Format)
write_def ${OUTPUT_DIR}/${DESIGN_NAME}_final.def

# Export GDS II
write_gds ${OUTPUT_DIR}/${DESIGN_NAME}.gds \
    -map_file $GDS_MAP_FILE \
    -unit 1000 \
    -structure top

# Export final netlist (post-route)
write_netlist ${OUTPUT_DIR}/${DESIGN_NAME}_postroute.v

# Export SDF for back-annotated simulation
write_sdf ${OUTPUT_DIR}/${DESIGN_NAME}_postroute.sdf

# Export SPEF for parasitic data
write_spef ${OUTPUT_DIR}/${DESIGN_NAME}_postroute.spef

puts "========================================"
puts "  Place & Route COMPLETE"
puts "  Results saved to: ${OUTPUT_DIR}/"
puts "========================================"

exit
