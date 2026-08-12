# release.ps1 - alle Varianten bauen, die Artefakte nach bin\ legen, changelog fortschreiben.
#
#   .\release.ps1 -Note "kurz, was diese Version aendert"
#   .\release.ps1 -Note "..." -Variants cyclone_10
#   .\release.ps1 -Note "..." -Force        vorhandene Datei ueberschreiben
#
# Die Versionsziffern kommen aus rtl\common\version_pkg.vhd (SW_SUB1/SW_SUB2) und
# variants\<n>\variant.psd1 (BoardId). Ein Release aendert genau EINE Ziffer in
# version_pkg.vhd, beide Boards folgen: RecelFA_v<BoardId><Sub1><Sub2>.jic
param(
    [Parameter(Mandatory)][string]$Note,
    [string[]]$Variants,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$VarRoot   = Join-Path $RepoRoot 'variants'
$BinRoot   = Join-Path $RepoRoot 'bin'
$Project   = 'RecelFA'

$verSrc = Get-Content (Join-Path $RepoRoot 'rtl\common\version_pkg.vhd') -Raw
if ($verSrc -notmatch 'SW_SUB1\s*:\s*std_logic_vector\(3 downto 0\)\s*:=\s*x"([0-9A-Fa-f])"') { throw 'SW_SUB1 nicht in version_pkg.vhd gefunden' }
$sub1 = $Matches[1]
if ($verSrc -notmatch 'SW_SUB2\s*:\s*std_logic_vector\(3 downto 0\)\s*:=\s*x"([0-9A-Fa-f])"') { throw 'SW_SUB2 nicht in version_pkg.vhd gefunden' }
$sub2 = $Matches[1]

$dirs = Get-ChildItem $VarRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'variant.psd1') }
if ($Variants) { $dirs = $dirs | Where-Object { $Variants -contains $_.Name } }
else {
    $dirs = $dirs | Where-Object {
        $m = Import-PowerShellDataFile (Join-Path $_.FullName 'variant.psd1')
        -not $m.Dormant
    }
}
if (-not $dirs) { throw 'keine Varianten zu releasen' }

$done = @()
foreach ($dir in $dirs) {
    $meta = Import-PowerShellDataFile (Join-Path $dir.FullName 'variant.psd1')
    $ver  = "$($meta.BoardId)$sub1$sub2"
    $ext  = $meta.ReleaseArtifact

    $target = if ($meta.BinFolder) { Join-Path $BinRoot $meta.BinFolder } else { $BinRoot }
    if (-not (Test-Path $target)) { New-Item -ItemType Directory $target | Out-Null }
    $dest = Join-Path $target "${Project}_v$ver.$ext"

    if ((Test-Path $dest) -and -not $Force) {
        throw "$dest gibt es schon. Version in rtl\common\version_pkg.vhd hochziehen oder -Force benutzen."
    }

    & (Join-Path $ScriptDir 'build.ps1') $dir.Name
    $src = Join-Path $dir.FullName "output_files\$Project.$ext"
    if (-not (Test-Path $src)) { throw "Artefakt fehlt: $src" }
    Copy-Item $src $dest -Force

    $sha = (Get-FileHash $dest -Algorithm SHA256).Hash.Substring(0, 16)
    $done += [pscustomobject]@{ Variant = $dir.Name; Version = "$($meta.BoardId).$sub1.$sub2"; File = (Split-Path $dest -Leaf); Sha = $sha }
}

# Dateiname wie bisher gepflegt (grosses C) - git ist gross/klein-empfindlich.
$log   = Join-Path $BinRoot 'Changelog.txt'
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'

# Kopfzeile im gewachsenen Stil dieser Datei ("-- v1.03 & v2.03 <Text>"), damit die
# Versionshistorie eine ueberfliegbare Liste bleibt. Darunter je Variante eine
# Nachweiszeile mit Artefakt und Pruefsumme - die fehlte bisher, und genau deshalb
# ist einmal unbemerkt eine .jic ausgeliefert worden, die nicht enthielt, was hier stand.
$headVers = (($done | Sort-Object Version | ForEach-Object { 'v{0}.{1}{2}' -f $_.Version.Split('.')[0], $sub1, $sub2 }) -join ' & ')
$lines = @('', "-- $headVers $Note", "   $stamp")
foreach ($d in ($done | Sort-Object Variant)) {
    $lines += "   {0,-16} {1,-8} {2}  sha256:{3}" -f $d.Variant, $d.Version, $d.File, $d.Sha
}
Add-Content -Path $log -Value $lines -Encoding UTF8

$done | Format-Table -AutoSize
Write-Host "In $log fortgeschrieben." -ForegroundColor Green
Write-Host "Nicht vergessen: in VARIANTEN.md eintragen, welche Variante tatsaechlich auf Hardware getestet wurde." -ForegroundColor Yellow
