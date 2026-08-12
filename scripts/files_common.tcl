# files_common.tcl - die Quellen, die JEDE RecelFA-Variante baut.
# Wird von scripts\gen_qsf.ps1 in variants\<n>\RecelFA.qsf eingesetzt.
#
# ALLE Pfade sind relativ zum QUARTUS-PROJEKTVERZEICHNIS, und das ist variants\<n>\ -
# daher ../../. Derselbe Bezug gilt fuer init_file in rtl/<familie>/HM6508_ram.vhd
# (../../rom/RecelFA.mif). Ausnahme: die .qip benutzen $::quartus(qip_path) und sind
# ortsunabhaengig - die nicht anfassen.
#
# Kein SEARCH_PATH. Jede Datei steht genau einmal explizit in einer Liste; nur so kann
# eine neue .vhd nicht in einer von zwei Varianten fehlen - und genau das war der Grund
# fuer den Umbau.
#
# Packages zuerst: variant_pkg liefert BOARD_ID, version_pkg die Softwareziffern.
# variant_pkg.vhd steht ohne Pfad, weil es IM Projektverzeichnis liegt.

set_global_assignment -name VHDL_FILE variant_pkg.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/version_pkg.vhd

set_global_assignment -name VHDL_FILE ../../rtl/common/EEprom.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/lisy_api.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/uart_tx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/uart_rx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/dfp_clk_gen.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/DFPlayer_Mini_CMD.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/gentones.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/uart_send.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/count_to_zero.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/byte_to_decimal.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/HM6508.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/read_the_dips.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/boot_message.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/counter_74HC4040.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/rA1761.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/Recel_init.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/r11696.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/rA17xx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/slow_to_fast_clock.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/SPI_Master.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/SD_Card.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/r10788.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/PPS4_2.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/cpu_clk_gen.vhd
set_global_assignment -name VHDL_FILE ../../top/RecelFA.vhd

# Initialisierungsdaten des HM6508-NVRAM.
set_global_assignment -name MIF_FILE ../../rom/RecelFA.mif

# Eine gemeinsame .sdc statt einer Kopie je Variante: sie referenziert ausschliesslich
# Hierarchienamen (rA1761:B1_IO|io_port_out[4], pps4:B4|addr[0], ...), die in beiden
# Varianten gleich sind. Erst wenn eine Variante boardspezifische Constraints braucht,
# gehoert sie in den Variantenordner.
set_global_assignment -name SDC_FILE ../../rtl/common/RecelFA.sdc
