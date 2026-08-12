@{
    Name        = 'cyclone_iv_v4'
    Title       = 'RecelFA-Platine mit dem Cyclone IV Board (EP4CE6E22C8)'
    BoardId     = 1
    RtlFamily   = 'cyclone_iv'      # welcher rtl\<familie>\-Ordner
    Options     = @()               # optionale files_<name>.tcl
    BinFolder   = ''                # bin\ flach: RecelFA_v1xx.jic
    ReleaseArtifact = 'jic'
    Dormant     = $false

    # Keine VIRTUAL_PIN noetig: beide Varianten haben dieselbe Portliste und alle
    # 82 Pins sind belegt. Der Mechanismus in gen_qsf.ps1 steht bereit, falls eine
    # Variante dazukommt, die einen dieser Ports nicht herausfuehrt.
    VirtualPins = @()

    Notes       = 'Ausgeliefert als RecelFA_v1xx.jic. Bis Etappe 1 (12.08.2026) fehlten hier die Timing-SDC und die HDL-Cleanups; seither identische Quellen wie cyclone_10.'
}
