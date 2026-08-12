@{
    Name        = 'cyclone_10'
    Title       = 'RecelFA-Platine mit dem Cyclone 10 Board (10CL006YE144C8G)'
    BoardId     = 2
    RtlFamily   = 'cyclone_10'      # welcher rtl\<familie>\-Ordner
    Options     = @()               # optionale files_<name>.tcl
    BinFolder   = ''                # bin\ flach: RecelFA_v2xx.jic
    ReleaseArtifact = 'jic'
    Dormant     = $false

    # Keine VIRTUAL_PIN noetig - siehe cyclone_iv_v4\variant.psd1.
    VirtualPins = @()

    Notes       = 'Ausgeliefert als RecelFA_v2xx.jic. Historie: das zuerst freigegebene v2.03 enthielt DFPlayer_Mini_CMD noch in v0.3 statt v0.6, obwohl der Changelog es behauptete - am 12.08.2026 mit korrigiertem Modul neu gebaut und ersetzt. Genau diese Art Divergenz soll der gemeinsame Sourcebaum abstellen.'
}
