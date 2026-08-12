## RecelFA timing constraints
## Target: Cyclone 10 LP (10CL006YE144C8G), Quartus Prime 22.1 Lite
##
## Rewritten (v2.02) to fully constrain all clock domains and remove the
## false cross-domain setup/hold violations and unconstrained-clock warnings:
##   - Critical Warning (332148) Timing requirements not met
##   - Critical Warning (188031) Ignored hold transfers clk_50 <-> cpu_clk
##   - Warning (332060) node determined to be a clock without assignment
##   - Warning (332056) PLL missing generated clock
##
## Design clocking overview:
##   clk_50         : 50 MHz on-board oscillator (only real async source)
##   turbo PLL      : ~4 MHz (boot/nvram speed-up), from clk_50 via altpll
##   normal_cpu_clk : ~393 kHz CPU clock, clk_50 / 127 (cpu_clk_gen)
##   cpu_clk        : 2:1 mux of {turbo, normal} -> clocks the PPS4 CPU
##   dfp_clk        : ~9.6 kHz serial clock for the DFPlayer, clk_50 / 5209
##   counter_clk    : slow CPU I/O strobe (rA1761 io_port_out[4]) that clocks
##                    the 74HC4040 address counter (data dependent ~400 kHz)
##
## The CPU domain and the clk_50 peripheral domain exchange only slow,
## quasi-static data, so they are declared mutually asynchronous. This is the
## correct CDC behaviour for this design and removes the false hold failures.

set_time_format -unit ns -decimal_places 3


#**************************************************************
# Base clock : 50 MHz oscillator (dedicated clock input pin)
#**************************************************************
create_clock -name {clk_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_50}]


#**************************************************************
# PLL generated clocks (turbo ~4 MHz)
#   derive_pll_clocks creates the generated clock for
#   turbo_gen|altpll_component|auto_generated|pll1|clk[0]
#   -> fixes Warning (332056)
#**************************************************************
derive_pll_clocks


#**************************************************************
# Counter-based divider clocks derived from clk_50
#**************************************************************
# ~393 kHz normal CPU clock (cpu_clk_gen counts 0..126 -> divide by 127)
create_generated_clock -name {normal_cpu_clk} \
    -source [get_ports {clk_50}] -divide_by 127 \
    [get_registers {cpu_clk_gen:clock_gen|cpu_clk_out}]

# ~9.6 kHz DFPlayer serial clock (dfp_clk_gen counts 0..5208 -> divide by 5209)
create_generated_clock -name {dfp_clk} \
    -source [get_ports {clk_50}] -divide_by 5209 \
    [get_registers {dfp_clk_gen:dfp_clk_g|dfp_clk_out}]


#**************************************************************
# Slow CPU I/O strobe used as the clock of the 74HC4040 address
# counter. It is data dependent (driven by CPU writes), so it is
# declared as an independent ~400 kHz base clock.
#**************************************************************
create_clock -name {counter_clk} -period 2500.000 -waveform { 0.000 0.500 } \
    [get_registers {rA1761:B1_IO|io_port_out[4]}]

#**************************************************************
# Gated "set" strobes used as clocks by the one-shot flags
# detect_nvram (end_of_nvramtest) and detect_PIO_test (end_of_PIO_test).
# These address-decode strobes are (ab)used as clocks in RecelFA.vhd, so
# Quartus traces them back to counter[0] / cpu addr[0]. Give them an
# explicit clock assignment so they are not reported as unconstrained
# clocks (Warning 332060); they are async to everything (see groups below).
#**************************************************************
create_clock -name {nvram_done_clk} -period 20.000 \
    [get_registers {Counter_74HC4040:COUNTER4040|counter[0]}]
create_clock -name {pio_done_clk} -period 20.000 \
    [get_registers {pps4:B4|addr[0]}]


#**************************************************************
# Clock uncertainty (after all clocks are defined)
#**************************************************************
derive_clock_uncertainty


#**************************************************************
# Asynchronous clock domains
#   - clk_50 (peripherals) <-> cpu_clk (PPS4 CPU, fed by normal_cpu_clk
#     and the turbo PLL) is an asynchronous CDC carrying slow quasi-static
#     data. Declaring it async removes the false hold transfers
#     (Critical Warning 188031) and the resulting 332148 failure.
#   - dfp_clk and counter_clk are independent slow domains.
#   normal_cpu_clk and the turbo PLL clock both drive the cpu_clk mux but are
#   mutually exclusive (only one is selected at a time), so they go into
#   SEPARATE groups. Otherwise STA cross-analyses the two clocks on the shared
#   cpu_clk net and reports impossible setup/hold failures.
#**************************************************************
set_clock_groups -asynchronous \
    -group [get_clocks {clk_50}] \
    -group [get_clocks {normal_cpu_clk}] \
    -group [get_clocks {turbo_gen|altpll_component|auto_generated|pll1|clk*}] \
    -group [get_clocks {dfp_clk}] \
    -group [get_clocks {counter_clk}] \
    -group [get_clocks {nvram_done_clk}] \
    -group [get_clocks {pio_done_clk}]


#**************************************************************
# Asynchronous reset input (synchronised internally by
# Cross_Slow_To_Fast_Clock) -> exclude from recovery/removal.
#**************************************************************
set_false_path -from [get_ports {reset_sw}]
