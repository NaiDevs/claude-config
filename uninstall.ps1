# uninstall.ps1 — Quita los archivos instalados por agent-ai-config
# Uso: .\uninstall.ps1
# Uso: .\uninstall.ps1 -Tool claude   (solo Claude Code)
# Uso: .\uninstall.ps1 -Tool codex    (solo Codex)
# Uso: .\uninstall.ps1 -IncludeMemory (quitar tambien la memoria — pide confirmacion)

param(
    [ValidateSet("","claude","codex","both")]
    [string]$Tool = "both",
    [switch]$IncludeMemory
)

$IsWin      = ($env:OS -eq "Windows_NT") -or ($PSVersionTable.Platform -eq "Win32NT") -or (-not $PSVersionTable.Platform)
$HomeDir    = if ($IsWin) { $env:USERPROFILE } else { $HOME }
$ClaudeHome = if ($IsWin) { "$HomeDir\.claude" } else { "$HomeDir/.claude" }
$CodexHome  = if ($IsWin) { "$HomeDir\.codex"  } else { "$HomeDir/.codex"  }
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path

$removed = @()
$skipped = @()

function Remove-IfExists {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
        $script:removed += $Label
        Write-Host "  Removido: $Label" -ForegroundColor Green
    } else {
        $script:skipped += $Label
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║   agent-ai-config — Uninstall         ║" -ForegroundColor Red
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "  Esto eliminara los archivos instalados por setup.ps1." -ForegroundColor Yellow
Write-Host "  NO modifica MCPs, settings.json ni configuracion externa." -ForegroundColor Yellow
Write-Host ""

$confirm = (Read-Host "  Continuar? (s/n) [n]").Trim().ToLower()
if ($confirm -ne "s") {
    Write-Host "  Cancelado." -ForegroundColor DarkGray
    exit 0
}
Write-Host ""

# ─── Claude Code ─────────────────────────────────────────────────────────────
if ($Tool -eq "claude" -or $Tool -eq "both") {
    Write-Host "[ Claude Code ]" -ForegroundColor Blue

    # Commands — solo los que vinieron de este repo
    Get-ChildItem "$ScriptDir\commands\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $target = "$ClaudeHome\commands\$($_.Name)"
        Remove-IfExists $target "commands/$($_.Name)"
    }

    Remove-IfExists "$ClaudeHome\hooks\on-git-commit.ps1" "hooks/on-git-commit.ps1"
    Remove-IfExists "$ClaudeHome\projects-registry.md"    "projects-registry.md (Claude)"

    Write-Host ""
}

# ─── Codex ────────────────────────────────────────────────────────────────────
if ($Tool -eq "codex" -or $Tool -eq "both") {
    Write-Host "[ Codex ]" -ForegroundColor Blue

    # Skills — solo los que vinieron de este repo
    Get-ChildItem "$ScriptDir\commands\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $skillDir = "$CodexHome\skills\$($_.BaseName)"
        Remove-IfExists $skillDir "skills/$($_.BaseName)"
    }

    Remove-IfExists "$CodexHome\projects-registry.md" "projects-registry.md (Codex)"

    Write-Host ""
}

# ─── Memoria — solo con confirmacion explícita ────────────────────────────────
if ($IncludeMemory) {
    Write-Host "[ Memoria Engram ]" -ForegroundColor Blue
    Write-Host "  ADVERTENCIA: esto borra el historial de cambios y contexto de proyectos." -ForegroundColor Red

    $confirmMem = (Read-Host "  Segura/o? Escribe 'BORRAR MEMORIA' para confirmar").Trim()
    if ($confirmMem -eq "BORRAR MEMORIA") {
        $EncodedHome = $HomeDir -replace "^([A-Za-z]):\\", '$1--' -replace "\\", "-"
        $MemPath = "$ClaudeHome\projects\$EncodedHome\memory"
        Remove-IfExists $MemPath           "memory (Claude Code)"
        Remove-IfExists "$CodexHome\memory" "memory (Codex)"
    } else {
        Write-Host "  Memoria conservada (confirmacion incorrecta)." -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ─── Resumen ──────────────────────────────────────────────────────────────────
Write-Host "─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Removidos : $($removed.Count) archivo(s)" -ForegroundColor Green
if ($skipped.Count -gt 0) {
    Write-Host "  No encontrados (OK): $($skipped.Count)" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "  Nota: settings.json y config.toml NO fueron modificados." -ForegroundColor DarkGray
Write-Host "  Para reinstalar: .\setup.ps1" -ForegroundColor DarkGray
Write-Host ""
