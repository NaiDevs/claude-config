# setup.ps1 — Instalar claude-config en este dispositivo
# Uso: .\setup.ps1
# Uso con path personalizado: .\setup.ps1 -ProjectsRoot "D:\MisProyectos"
param(
    [string]$ProjectsRoot = "$env:USERPROFILE\OneDrive\Documentos\Proyectos"
)

$ClaudeHome = "$env:USERPROFILE\.claude"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ErrorActionPreference = "Stop"

Write-Host "=== Instalando claude-config ===" -ForegroundColor Cyan
Write-Host "Usuario:       $env:USERNAME"
Write-Host "Claude home:   $ClaudeHome"
Write-Host "Proyectos:     $ProjectsRoot"
Write-Host ""

# 1. Comandos custom — instalar en commands/ (ubicación correcta de Claude Code)
Write-Host "1. Instalando comandos custom..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force "$ClaudeHome\commands" | Out-Null
Copy-Item "$ScriptDir\commands\*.md" "$ClaudeHome\commands\" -Force
Write-Host "   OK -> $((Get-ChildItem "$ScriptDir\commands\*.md").Count) comandos instalados en $ClaudeHome\commands\" -ForegroundColor Green

# Limpiar ~/.claude/skills/ si tiene archivos viejos (skills/ era la ubicación incorrecta)
$skillsPath = "$ClaudeHome\skills"
if (Test-Path $skillsPath) {
    $oldFiles = Get-ChildItem $skillsPath -ErrorAction SilentlyContinue
    if ($oldFiles.Count -gt 0) {
        $oldFiles | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   OK -> $($oldFiles.Count) archivo(s) eliminado(s) de skills/ (ubicación obsoleta)" -ForegroundColor DarkYellow
    }
}

# 2. CLAUDE.md global — reglas siempre activas + auto-activación de skills
Write-Host "2. Instalando CLAUDE.md global..." -ForegroundColor Yellow
Copy-Item "$ScriptDir\CLAUDE.md" "$ClaudeHome\CLAUDE.md" -Force
Write-Host "   OK -> $ClaudeHome\CLAUDE.md" -ForegroundColor Green

# 3. Registry editable
Write-Host "2. Copiando registry de proyectos..." -ForegroundColor Yellow
Copy-Item "$ScriptDir\projects-registry.md" "$ClaudeHome\projects-registry.md" -Force
Write-Host "   OK -> $ClaudeHome\projects-registry.md" -ForegroundColor Green
Write-Host "   (edita este archivo para cambiar aliases y workspaces)"

# 3. Detectar path de memoria de Claude Code
# Claude Code codifica el homepath: C:\Users\naide -> C--Users-naide
Write-Host "3. Detectando path de memoria..." -ForegroundColor Yellow
$HomePath = $env:USERPROFILE
$EncodedHome = $HomePath -replace "^([A-Za-z]):\\", '$1--' -replace "\\", "-"
$MemoryPath = "$ClaudeHome\projects\$EncodedHome\memory"
New-Item -ItemType Directory -Force $MemoryPath | Out-Null
Write-Host "   Path codificado: $EncodedHome"
Write-Host "   Memoria en:      $MemoryPath"

# 4. Copiar archivos de memoria
Write-Host "4. Instalando archivos de memoria..." -ForegroundColor Yellow
Copy-Item "$ScriptDir\memory\*.md" "$MemoryPath\" -Force
Write-Host "   OK -> $((Get-ChildItem "$ScriptDir\memory\*.md").Count) archivos copiados" -ForegroundColor Green

# 5. Actualizar MEMORY.md (sin duplicar entradas)
Write-Host "5. Actualizando MEMORY.md..." -ForegroundColor Yellow
$MemoryIndex = "$MemoryPath\MEMORY.md"
$NewEntries = @(
    "- [Proyectos YALO](projects-yalo.md) — 22 subproyectos POS/pagos, aliases ``yalo *``",
    "- [Proyectos La Bodega](projects-labodega.md) — 10 subproyectos ecommerce, aliases ``bodega *``",
    "- [Proyectos CORINSA](projects-corinsa.md) — 7 subproyectos BI/CPA, aliases ``corinsa *`` y ``cpa *``",
    "- [Proyectos Ultimate Labs](projects-ultimatelabs.md) — 6 subproyectos labs, aliases ``ult *``",
    "- [Proyectos EMSULA + NAI](projects-otros.md) — 12 subproyectos médicos y personales",
    "- [Workspaces](projects-workspaces.md) — Grupos de repos para trabajo simultáneo con git sync"
)

$existing = if (Test-Path $MemoryIndex) { Get-Content $MemoryIndex } else { @() }
$toAdd = $NewEntries | Where-Object { $existing -notcontains $_ }
if ($toAdd.Count -gt 0) {
    if (-not (Test-Path $MemoryIndex)) {
        "# Memory Index" | Set-Content $MemoryIndex -Encoding utf8
    }
    $toAdd -join "`n" | Add-Content $MemoryIndex -Encoding utf8
    Write-Host "   OK -> $($toAdd.Count) entradas agregadas a MEMORY.md" -ForegroundColor Green
} else {
    Write-Host "   OK -> MEMORY.md ya estaba actualizado" -ForegroundColor Green
}

# 6. Hook de git fetch (mostrar fragmento para agregar manualmente)
Write-Host ""
Write-Host "6. Hook de git fetch (opcional)" -ForegroundColor Yellow
Write-Host "   Para tener info del remoto actualizada automaticamente, agrega esto"
Write-Host "   a $ClaudeHome\settings.json en la seccion 'hooks':"
Write-Host ""
Get-Content "$ScriptDir\settings-hook.json"
Write-Host ""

Write-Host "=== Instalacion completa ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proximos pasos:"
Write-Host "  1. Reinicia Claude Code"
Write-Host "  2. Usa /proyecto para ver todos los proyectos"
Write-Host "  3. Usa /proyecto yalo bo para activar un proyecto"
Write-Host "  4. Edita $ClaudeHome\projects-registry.md para personalizar aliases"
Write-Host ""
