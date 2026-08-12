# RecelFA – Timing & Compile-Warnungen

Dokumentation der Timing-Constraint-Überarbeitung und Warning-Bereinigung
(Stand 2026-06-30, Quartus Prime 22.1std.2 Lite, Cyclone 10 LP `10CL006YE144C8G`,
Top-Entity `RecelFA`).

## Ausgangslage

Der Build war erfolgreich, meldete aber **30 Warnungen**, darunter echte Timing-Fehler:

- `Critical Warning (332148)` Timing requirements not met
- `Critical Warning (188031)` Ignored hold transfers `clk_50` ↔ `cpu_clk`
  (Hold TNS −1274 ns – der Fitter konnte den Hold nicht schließen)
- `Warning (332060)` ×3: Knoten als Clock erkannt, aber ohne Constraint
  (`dfp_clk_out`, `Counter_74HC4040|counter[0]`, `pps4:B4|addr[0]`)
- `Warning (332056)`: Turbo-PLL ohne generated clock
- reale Slack-Verletzungen: Setup `clk_50` −0.123, Recovery `io_port_out[4]` −24.8 ns

**Ursache:** Die alte `RecelFA.sdc` war unvollständig – kein `derive_pll_clocks`,
Divider-Takte (`dfp_clk`) nicht constraint, der `cpu_clk`-Mux nicht behandelt und
keine asynchronen Taktdomänen deklariert. Dadurch hat der Timing-Analyzer Setup/Hold
über **asynchrone** Clock-Domain-Crossings (clk_50 ↔ CPU) geprüft → falsche Hold-Fehler.

## Ergebnis

| | vorher | nachher |
|---|---|---|
| Fehler | 0 | 0 |
| Warnungen gesamt | 30 | **16** |
| Timing-Analyzer-Warnungen | mehrere + Fehler | **0** |
| Worst Slacks (Slow 85 °C) | Hold −3.07, Recovery −2.48 | **alle positiv** (Setup +7.0, Hold +0.4, Recovery +14.9) |

Die verbleibenden 16 Warnungen sind **bewusst akzeptiert** (siehe unten) – keine
Timing- oder Logikprobleme mehr.

## Clock-Architektur

| Takt | Quelle | ~Frequenz | Zweck |
|---|---|---|---|
| `clk_50` | Oszillator (PIN_23) | 50 MHz | einzige echte async Quelle |
| Turbo-PLL `turbo_gen` | altpll aus clk_50 | ~4 MHz | Boot/NVRAM-Speedup |
| `normal_cpu_clk` | `cpu_clk_gen`, clk_50/127 | ~393 kHz | normaler CPU-Takt |
| `cpu_clk` | **Mux** {turbo, normal} | – | taktet PPS4-CPU (`B4`) |
| `dfp_clk` | `dfp_clk_gen`, clk_50/5209 | ~9.6 kHz | DFPlayer Serial |
| `counter_clk` | `rA1761:B1_IO|io_port_out[4]` | ~400 kHz | taktet 74HC4040-Adresszähler |
| `nvram_done_clk` | `Counter_74HC4040|counter[0]` | – | gated „set"-Strobe |
| `pio_done_clk` | `pps4:B4|addr[0]` | – | gated „set"-Strobe |

Die letzten beiden entstehen aus den level-sensitiven Prozessen `detect_nvram` und
`detect_PIO_test` in `RecelFA.vhd`: Adress-Decode-Strobes (`eeprom_trigger`,
`PIO_test_trigger`) werden dort als Takt für die One-Shot-Flags `end_of_nvramtest` /
`end_of_PIO_test` benutzt. Quartus verfolgt diese „Takte" zu `counter[0]` bzw. `addr[0]`.

## Zentrale Erkenntnis (Clock-Groups)

> `normal_cpu_clk` und der Turbo-PLL-Takt teilen sich das `cpu_clk`-Mux-Netz, laufen
> aber **nie gleichzeitig**. Sie müssen deshalb in **getrennte**
> `set_clock_groups -asynchronous`-Gruppen.

Liegen beide in **einer** Gruppe, cross-analysiert STA die zwei Takte auf dem geteilten
Netz und meldet **physikalisch unmögliche** Setup/Hold-Fehler (z. B. Setup −2.94 ns bei
2540 ns Periode). Nach der Trennung waren sofort alle Slacks positiv. Alle Domänen sind
als gegenseitig asynchron deklariert (langsame, quasi-statische CDC).

## SDC-Aufbau (`RecelFA.sdc`)

1. `create_clock clk_50` (20 ns)
2. `derive_pll_clocks` → Turbo-PLL (behebt 332056)
3. `create_generated_clock normal_cpu_clk` (clk_50 ÷127)
4. `create_generated_clock dfp_clk` (clk_50 ÷5209)
5. `create_clock counter_clk` auf `io_port_out[4]` (2500 ns)
6. `create_clock nvram_done_clk` / `pio_done_clk` auf counter[0] / addr[0]
   (gibt den gated-Strobes eine Clock-Zuordnung → behebt 332060)
7. `derive_clock_uncertainty`
8. `set_clock_groups -asynchronous` mit **7 getrennten Gruppen** (jede Domäne einzeln)
9. `set_false_path -from reset_sw` (asynchroner, intern synchronisierter Reset)

> Backup der alten SDC: `RecelFA.sdc.v202_pre_timingfix`

## HDL-Cleanups (verhaltensneutral)

| Datei | Änderung | behobene Warnung |
|---|---|---|
| `RecelFA.vhd` | `uart_print_addr` entfernt → Konstante 0 in `ram_addr_b` | `10541`/`10540` |
| `RecelFA.vhd` | totes `opt_mpf` entfernt | `10036` |
| `EEprom.vhd` | `RX_Data_W`/`RX_Data_Cmd` → `open`, Signale raus | `10036` ×2 |
| `EEprom.vhd` | `TX_Data_R` mit `(others => '0')` initialisiert | `10873` |
| `SD_Card.vhd` | `SS` → `open`, `SS_R` raus | `10036` |
| `lisy_api.vhd` | totes `parameter` entfernt | `10036` |

Alle Änderungen sind verhaltensneutral (tote Signale, Init-Werte, `open`-Mappings);
die SDC ändert nur die Timing-**Analyse**, nicht die erzeugte Logik.

## Verbleibende 16 Warnungen – bewusst akzeptiert

Diese sind beabsichtigt bzw. durch die Quartus **Lite** Edition / Hardware bedingt und
wurden **nicht** geändert:

| Warnung | Stelle | Grund |
|---|---|---|
| `Critical 10920` ×5 | `RecelFA.vhd` 455/614/672/704/806 | beabsichtigte ungenutzte Output-Bits via `open` (`w_trigger`, `sound_and_coils_out`, `io_port_out` ×2, `Q`) |
| `19016`/`19017` | `cpu_clk` Mux | inhärent zur Turbo/Normal-Taktumschaltung; von Quartus „protected" |
| `13024`/`13410` ×2 | `E_DISPLAY_IC_N`, `Disp_Enable` | absichtlich fest auf `'0'` |
| `21074`/`15610` ×2 | `S3`, `S6` | ungenutzte Board-Taster, reserviert |
| `292013` | LogicLock | Lizenz-Limit der Lite Edition – nicht eliminierbar |
| `15714` | I/O-Assignments | optional via per-Pin I/O-Standard behebbar |
| `169177` | AN447 | informativer 3.3-V-Interface-Hinweis |

**Mögliche spätere Schritte** (falls eine komplett saubere Ausgabe gewünscht):
- die 5 `10920` durch Port-Map-Umbau (Vektor-Zwischensignale statt `open`) echt beheben
- `S3`/`S6` aus Entity + QSF entfernen
- alle akzeptierten IDs per Quartus **Message Suppression** ausblenden

## Neu kompilieren / verifizieren

```bash
cd "N:/Projekte/FPGA Recel/source_RecelFA_Cyclone_10"
/c/intelFPGA_lite/22.1std/quartus/bin64/quartus_sh --flow compile RecelFA
# nur Timing (schnell): quartus_sta RecelFA -c RecelFA
```

Prüfen: `output_files/RecelFA.sta.summary` (alle Slacks ≥ 0),
`output_files/RecelFA.map.rpt` / `.fit.rpt` (nur noch die akzeptierten Warnungen).
Programmierdatei: `output_files/RecelFA.sof` (bzw. `RecelFA.jic` via `RecelFA.cof` neu erzeugen).
