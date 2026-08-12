# RecelFA

VHDL-Nachbau der **Recel III** Flipper-MPU (Rockwell PPS/4-2) auf einem Altera/Intel FPGA,
inklusive Displays, Solenoids, Lampen, NVRAM und Hintergrundsound über ein
DFPlayer-Mini-Modul. Hardware und Hintergrund: <https://lisy.dev/recel3.html>

## Boards

| Variante | FPGA-Board | Device | Angezeigte Version | Release |
|---|---|---|---|---|
| `cyclone_iv_v4` | Cyclone IV Piggyback | `EP4CE6E22C8` | `1.x.y` | `bin/RecelFA_v1xx.jic` |
| `cyclone_10` | Cyclone 10 Piggyback | `10CL006YE144C8G` | `2.x.y` | `bin/RecelFA_v2xx.jic` |

Beide teilen **ein** Top-Level (`top/RecelFA.vhd`) und einen Quellbaum. Was sich je Board
unterscheidet, sind fünf Pin-Locations, das Device und eine Konstante.

Die angezeigte Version ist `BOARD_ID.SW_SUB1.SW_SUB2`: die führende Ziffer kennzeichnet
das Board (`variants/<name>/variant_pkg.vhd`), die beiden anderen sind die gemeinsame
Softwareversion (`rtl/common/version_pkg.vhd`). Ein Release ändert genau eine Ziffer,
und beide Boards folgen.

## Layout

```
top/RecelFA.vhd        DAS eine Top-Level
rtl/common/            die 24 gemeinsamen Module + version_pkg + RecelFA.sdc
rtl/cyclone_iv/        Megafunctions für Cyclone IV E
rtl/cyclone_10/        dieselben sechs IP-Blöcke für Cyclone 10 LP
rom/RecelFA.mif        Initialisierungsdaten des HM6508-NVRAM
variants/<name>/       variant.psd1, device.tcl, pins.tcl, variant_pkg.vhd,
                       RecelFA.qpf, RecelFA.cof  +  RecelFA.qsf (GENERIERT)
scripts/               gen_qsf.ps1, check.ps1, build.ps1, release.ps1, baseline.csv
bin/                   ausgelieferte .jic + changelog.txt
docs/                  WORKFLOW.md, TIMING_AND_WARNINGS.md
archive/               alte Modulstände, in keinem Build
```

**`variants/<name>/RecelFA.qsf` niemals von Hand ändern** – sie wird aus den Fragmenten
in `scripts/` und `variants/<name>/` erzeugt. Quartus schreibt selbst hinein, sobald das
Projekt in der IDE offen ist; genau deshalb wird sie vor jedem Build neu erzeugt.

## Build

```powershell
powershell -File scripts\gen_qsf.ps1 -Check      # .qsf aktuell?
powershell -File scripts\check.ps1               # beide Varianten synthetisieren
powershell -File scripts\check.ps1 -Fit          # + Fitter und Timing
powershell -File scripts\build.ps1 cyclone_10    # voller Flow inkl. .jic
powershell -File scripts\release.ps1 -Note "..." # bauen, nach bin\ legen, changelog
```

Toolchain: Quartus Prime **22.1std.2 Lite** (`C:\intelFPGA_lite\22.1std`). Dieselbe
Installation baut beide Familien.

Wie man hier arbeitet – und was wo hingehört – steht in [docs/WORKFLOW.md](docs/WORKFLOW.md).

## Repository-Hinweis

Dieser Baum ist am 12.08.2026 aus den beiden flachen Projektordnern
`source_RecelFA_cyclone_IV_v4` und `source_RecelFA_Cyclone_10` entstanden. Die liegen
weiterhin daneben als Backup – **von dort nicht mehr bauen und nicht committen.**

## Dritte

`SPI_Master.vhd`, `uart_rx.vhd`, `uart_tx.vhd` stammen von nandland.com.
Die Megafunctions unter `rtl/<familie>/` sind vom Intel MegaWizard erzeugt.
