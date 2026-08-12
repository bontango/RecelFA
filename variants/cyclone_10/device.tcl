# device.tcl - was fuer DIESES Board gilt, ausser den Pinlagen.
# Wird von scripts\gen_qsf.ps1 in RecelFA.qsf eingesetzt. Handgepflegt.
#
# Gleiche Quartus-Installation wie cyclone_iv_v4 (22.1std unterstuetzt beide Familien),
# deshalb braucht check.ps1 hier keine Versionstabelle.
set_global_assignment -name FAMILY "Cyclone 10 LP"
set_global_assignment -name DEVICE 10CL006YE144C8G
set_global_assignment -name LAST_QUARTUS_VERSION "22.1std.2 Lite Edition"
