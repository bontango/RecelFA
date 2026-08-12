# files_cyclone_iv.tcl - die Megafunctions fuer Cyclone IV E (EP4CE6E22C8).
#
# Dieselben Entity-Namen und Portlisten wie in rtl/cyclone_10/ - im VHDL steht kein
# einziges Familien-Konstrukt, die .qsf entscheidet allein ueber RtlFamily in
# variants/<n>/variant.psd1.
#
# Die .qip benutzen [file join $::quartus(qip_path) ...] und finden ihre .vhd/.cmp
# selbst; deshalb steht hier nur der Pfad zur .qip.

set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/B1_ROM.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/B2_ROM.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/Game_ROM.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/ROM.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/HM6508_ram.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/turbo.qip
