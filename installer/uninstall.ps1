<#
  Desinstalador del toolkit PokeAccess. Quita el cargador de mkxp.json y borra la
  carpeta accessibility\. No toca Scripts.rxdata ni partidas guardadas.
#>
param([string]$GameDir)

$ErrorActionPreference = "Stop"
$marker = "accessibility/preload_access.rb"

function Pause-Exit { Write-Host "`nPulsa una tecla para salir..."; try { [void][System.Console]::ReadKey($true) } catch {} }
function Fail($msg) { Write-Host "`n[ERROR] $msg" -ForegroundColor Red; Pause-Exit; exit 1 }

# opens the Windows folder picker (accessible with a screen reader); falls back to a
# typed path if it cannot be shown or is cancelled.
function Pick-Folder {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = "Elige la carpeta del juego a desinstalar"
        $dlg.ShowNewFolderButton = $false
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dlg.SelectedPath }
    } catch {}
    Write-Host "Escribe o pega la ruta de la carpeta del juego y pulsa Enter:"
    return (Read-Host).Trim('"')
}

if (-not $GameDir) { $GameDir = Pick-Folder }
if (-not $GameDir -or -not (Test-Path $GameDir)) { Fail "No se eligio una carpeta valida." }

$json = Join-Path $GameDir "mkxp.json"
$bak  = "$json.access.bak"
if (Test-Path $bak) {
    Copy-Item $bak $json -Force
    Remove-Item $bak -Force
    Write-Host "[OK] mkxp.json restaurado a su estado original." -ForegroundColor Green
}
elseif (Test-Path $json) {
    $content = Get-Content $json -Raw
    $content = $content -replace '(?s)\{\s*// === MOD DE ACCESIBILIDAD.*?"preloadScript"\s*:\s*\[".*?"\],\s*', "{`n"
    $content = $content -replace ('"' + [regex]::Escape($marker) + '"\s*,\s*'), ""
    $content = $content -replace ('\s*,\s*"' + [regex]::Escape($marker) + '"'), ""
    $content = $content -replace ('"' + [regex]::Escape($marker) + '"'), ""
    [System.IO.File]::WriteAllText($json, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "[OK] Cargador retirado de mkxp.json." -ForegroundColor Green
}

$dst = Join-Path $GameDir "accessibility"
if (Test-Path $dst) {
    Remove-Item $dst -Recurse -Force
    Write-Host "[OK] Carpeta accessibility eliminada." -ForegroundColor Green
}

Write-Host "`nMod desinstalado. El juego queda como estaba." -ForegroundColor Cyan
Pause-Exit
