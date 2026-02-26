# ==============================================================================
# SDC Timing Constraints for ripple_carry_adder_4bit
# NOTE: This is a purely combinational design (no clock).
# ==============================================================================

# Set the design
set_units -time ns -capacitance pF

# Since this is a combinational design, we define a virtual clock
# to constrain input-to-output delay
create_clock -name vclk -period 10.0

# Input delay constraints (relative to virtual clock)
set_input_delay  -clock vclk -max 2.0 [get_ports {a[*] b[*] cin}]
set_input_delay  -clock vclk -min 0.5 [get_ports {a[*] b[*] cin}]

# Output delay constraints (relative to virtual clock)
set_output_delay -clock vclk -max 2.0 [get_ports {sum[*] cout}]
set_output_delay -clock vclk -min 0.5 [get_ports {sum[*] cout}]

# Max combinational path delay (input to output): 5ns target
set_max_delay 5.0 -from [get_ports {a[*] b[*] cin}] -to [get_ports {sum[*] cout}]

# Input transition constraints
set_input_transition -max 0.5 [get_ports {a[*] b[*] cin}]

# Output load
set_load 0.05 [get_ports {sum[*] cout}]

# Operating conditions (typical)
# set_operating_conditions -max typical -library <your_lib>
