# files_cyclone_10.tcl - die Megafunctions fuer Cyclone 10 LP (10CL006YE144C8G).
#
# Dieselben Entity-Namen und Portlisten wie in rtl/cyclone_iv/ - im VHDL steht kein
# einziges Familien-Konstrukt, die .qsf entscheidet allein ueber RtlFamily in
# variants/<n>/variant.psd1.
#
# Die .qip benutzen [file join $::quartus(qip_path) ...] und finden ihre .vhd/.cmp
# selbst; deshalb steht hier nur der Pfad zur .qip.

set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/B1_ROM.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/B2_ROM.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/Game_ROM.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/ROM.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/HM6508_ram.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/turbo.qip
