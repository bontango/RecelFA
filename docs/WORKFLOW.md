# RecelFA – Arbeiten am gemeinsamen Sourcebaum

## Die eine Regel

`variants/<name>/RecelFA.qsf` ist **erzeugt**. Sie wird nie von Hand geändert.
Sie entsteht aus sechs Bausteinen:

| Baustein | Inhalt | gepflegt von |
|---|---|---|
| `scripts/common_header.tcl` | globale Assignments, für alle Varianten gleich | Hand |
| `variants/<n>/device.tcl` | FAMILY, DEVICE, LAST_QUARTUS_VERSION | Hand |
| `variants/<n>/pins.tcl` | die Pinlagen dieses Boards | Hand |
| `variants/<n>/variant.psd1` | Metadaten, VIRTUAL_PIN, RtlFamily | Hand |
| `scripts/files_common.tcl` | gemeinsame Quellen, `.mif`, `.sdc` | Hand |
| `scripts/files_<familie>.tcl` | die Megafunctions dieser FPGA-Familie | Hand |

## Was du ändern willst → wo es hingehört

| Vorhaben | Ort |
|---|---|
| Logik ändern | `rtl/common/*.vhd` bzw. `top/RecelFA.vhd` |
| **neue** `.vhd` anlegen | Datei nach `rtl/common/` **und** Zeile in `scripts/files_common.tcl` |
| Pin verschieben | `variants/<n>/pins.tcl` |
| Port, den ein Board nicht hat | Port bleibt im Top-Level, Name in `VirtualPins` der `variant.psd1` |
| anderer FPGA / andere Quartus-Version | `variants/<n>/device.tcl` |
| Softwareversion hochziehen | **nur** `rtl/common/version_pkg.vhd` |
| Board-Kennziffer | `variants/<n>/variant_pkg.vhd` |
| Timing-Constraint | `rtl/common/RecelFA.sdc` (gilt für beide Boards) |
| `.sof` → `.jic` | `variants/<n>/RecelFA.cof`, Pfade **relativ** |
| neue Variante | Ordner unter `variants/` mit den sechs Handdateien, dann `gen_qsf.ps1` |
| Megafunction ändern | in **jeder** `rtl/<familie>/` neu erzeugen, sonst laufen die Familien auseinander |

## Ablauf einer Änderung

1. Ändern.
2. `powershell -File scripts\check.ps1` – Synthese beider Varianten gegen `baseline.csv`.
3. `powershell -File scripts\check.ps1 -Fit` – Ressourcen und Timing.
4. `powershell -File scripts\build.ps1 cyclone_10` → flashen → **auf der Maschine testen**.
5. Version in `rtl/common/version_pkg.vhd` hochziehen.
6. `powershell -File scripts\release.ps1 -Note "..."` – baut beide, legt nach `bin/`,
   schreibt `bin/changelog.txt` fort.
7. Ein Commit für beide Varianten, ein Tag.

Ist eine Ressourcenänderung beabsichtigt, wird `scripts/baseline.csv` nachgezogen –
**mit Begründung in der Note-Spalte**. Ohne Begründung ist die Baseline wertlos.

## Abnahmekriterium

Verglichen werden die **Synthese**-Zahlen aus `map.rpt`: *Total combinational functions*,
*Total registers*, *Total memory bits*. Die sind eine Eigenschaft des Designs.

Die **LE-Zahl des Fitters taugt nicht** dafür – sie ändert sich schon dann, wenn der
Fitter anders packt, ohne dass sich funktional etwas geändert hat. Sie wird nur
mitgeführt. Slack ebenso: Toleranz 1,5 ns plus ein absoluter Boden bei 1,0 ns.

## Quartus-IDE

Die IDE darf benutzt werden, aber:

- **keine Dateien über die IDE hinzufügen** – sie schreibt sie in die `.qsf`, und die
  wird beim nächsten `gen_qsf.ps1` überschrieben. Der Eintrag gehört in
  `scripts/files_common.tcl`.
- Änderungen im Pin Planner sofort nach `variants/<n>/pins.tcl` übertragen.
- Nach einer IDE-Sitzung `powershell -File scripts\gen_qsf.ps1 -Check` laufen lassen.

## Stolperfallen, die hier schon zugeschlagen haben

1. **Alle Pfade sind projektverzeichnisrelativ, und das Projektverzeichnis ist
   `variants/<n>/`.** Quellen `../../rtl/…`, `init_file` `../../rom/RecelFA.mif`,
   `.cof` `output_files/RecelFA.sof`. **Ausnahme `.qip`:** die benutzen
   `[file join $::quartus(qip_path) …]` und sind ortsunabhängig – nicht anfassen.
2. **`init_file` ohne Pfad** (`"RecelFA.mif"`) wird ebenfalls relativ zum
   Projektverzeichnis aufgelöst und bricht beim Umzug genauso wie ein `./`-Pfad.
   Beim Suchen nach `init_file` greppen, nicht nach `../`.
3. **Der `<sof_filename>` in der `.cof` war absolut** und zeigte in den alten flachen
   Ordner. Beim Kopieren einer Variante brennt man damit die `.sof` des falschen Boards.
4. **Ein deklarierter Ausgangsport ohne Pin-Location ist für Quartus ein benutzter Pin.**
   `RESERVE_ALL_UNUSED_PINS` greift dafür nicht. Wo ein Board einen Port nicht hat:
   `VirtualPins` in der `variant.psd1`. RecelFA braucht das derzeit nicht – beide
   Varianten haben dieselbe Portliste und alle 82 Pins belegt.
5. **`sed -i` aus der Git-Bash zerstört CRLF.** Danach sieht ein Ein-Zeilen-Diff aus wie
   ein Totalumbau. Textersetzungen in diesem Baum über PowerShell mit
   `[System.IO.File]::WriteAllText` und `UTF8Encoding($false)` machen.
6. **Generierte Megafunction-Wrapper nicht blind kopieren.** In `HM6508_ram.vhd` unter-
   schieden sich die beiden Familien nicht nur im `intended_device_family`, sondern im
   Parameter `read_during_write_mode` – eine echte Divergenz, getarnt als Family-Artefakt.
7. **Die `.sdc` referenziert Hierarchienamen** (`rA1761:B1_IO|io_port_out[4]`,
   `pps4:B4|addr[0]`, `turbo_gen|altpll_component|…`). Wandert eine davon in ein
   `generate` oder wird eine Instanz umbenannt, brechen die Constraints **stumm**.
8. **`numeric_std` steht hier neben `std_logic_unsigned`.** Das geht so lange gut, wie
   keine mehrdeutige Überladung benutzt wird; beim Anfassen arithmetischer Ausdrücke
   kann `Error 10327` auftauchen.
