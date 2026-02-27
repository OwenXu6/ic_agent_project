# ==============================================================================
# SDC Constraints for 8-bit ALU
# Technology: TSMC 65nm GP — Target 200 MHz (5 ns period)
# ==============================================================================

# Real clock on clk port
create_clock -name clk -period 5.0 -waveform {0 2.5} [get_ports clk]

# Clock uncertainty (setup + hold jitter budget)
set_clock_uncertainty -setup 0.1 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]

# Input delays (registered from upstream FF, 1 ns after clock edge)
set_input_delay -clock clk -max 1.0 [get_ports {a[*]}]
set_input_delay -clock clk -min 0.2 [get_ports {a[*]}]
set_input_delay -clock clk -max 1.0 [get_ports {b[*]}]
set_input_delay -clock clk -min 0.2 [get_ports {b[*]}]
set_input_delay -clock clk -max 1.0 [get_ports {opcode[*]}]
set_input_delay -clock clk -min 0.2 [get_ports {opcode[*]}]
set_input_delay -clock clk -max 0.2 [get_ports rst_n]
set_input_delay -clock clk -min 0.0 [get_ports rst_n]

# Output delays (consumed by downstream FF, must settle 1 ns before capture edge)
set_output_delay -clock clk -max 1.0 [get_ports {result[*]}]
set_output_delay -clock clk -min 0.2 [get_ports {result[*]}]
set_output_delay -clock clk -max 1.0 [get_ports carry_out]
set_output_delay -clock clk -min 0.2 [get_ports carry_out]
set_output_delay -clock clk -max 1.0 [get_ports zero]
set_output_delay -clock clk -min 0.2 [get_ports zero]

# Driving cell on inputs (TSMC 65nm INVD1)
set_driving_cell -lib_cell INVD1 -pin ZN [get_ports {a[*]}]
set_driving_cell -lib_cell INVD1 -pin ZN [get_ports {b[*]}]
set_driving_cell -lib_cell INVD1 -pin ZN [get_ports {opcode[*]}]

# Output load (0.05 pF)
set_load -pin_load 0.05 [get_ports {result[*]}]
set_load -pin_load 0.05 [get_ports carry_out]
set_load -pin_load 0.05 [get_ports zero]

# Max transition / fanout
set_max_transition 0.5 [current_design]
set_max_fanout     8   [current_design]
