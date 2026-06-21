# auto-update.ps1 - Verifica si el repo tiene cambios remotos y actualiza
# Uso: .\auto-update.ps1 [-Tool claude|codex|both|auto]
param(
    [ValidateSet("auto","claude","codex","both")]
    [string]$Tool = "auto",
    [switch]$Silent
)

$repo    = "$env:USERPROFILE\OneDrive\Documentos\Proyectos\Nai\agent-ai-config"
$logFile = "$repo\.last-update.log"

if (-not (Test-Path "$repo\.git")) {
    if (-not $Silent) { Write-Host "[agent-ai-config] Repo no encontrado en $repo" -ForegroundColor Yellow }
    exit 0
}

# Throttle: no verificar mas de una vez cada 30 minutos en sesion
$lastCheck = if (Test-Path $logFile) { (Get-Item $logFile).LastWriteTime } else { [DateTime]::MinValue }
if (([DateTime]::Now - $lastCheck).TotalMinutes -lt 30 -and -not $env:FORCE_UPDATE) { exit 0 }

[DateTime]::Now.ToString() | Set-Content $logFile -Encoding utf8

# Actualizar agent-config
git -C $repo fetch origin master --quiet 2>$null
$behind = (git -C $repo rev-list "HEAD..origin/master" --count 2>$null).Trim()

if ([int]$behind -gt 0) {
    Write-Host ""
    Write-Host "agent-ai-config: $behind commit(s) nuevos - actualizando..." -ForegroundColor Cyan
    git -C $repo pull origin master --quiet
    & "$repo\setup.ps1" -Tool $Tool
    Write-Host "Actualizacion completada." -ForegroundColor Green
    Write-Host ""
} else {
    if (-not $Silent) { Write-Host "[agent-ai-config] Al dia" -ForegroundColor DarkGray }
}

# Sincronizar cambios locales de vuelta al repo
& "$repo\sync.ps1" -Silent

# Actualizar YALO-SKILLS y redesplegar skills
$deployScript = Join-Path $repo "yalo-skills-deploy.ps1"
if (Test-Path $deployScript) {
    # Intentar leer ProjectsRoot desde settings de Claude Code; si no, usar default
    $settingsFile  = "$env:USERPROFILE\.claude\settings.json"
    $projectsRoot  = ""
    if (Test-Path $settingsFile) {
        try {
            $s = Get-Content $settingsFile -Raw | ConvertFrom-Json
            $fsArgs = $s.mcpServers.filesystem.args
            if ($fsArgs -and $fsArgs.Count -gt 2) { $projectsRoot = $fsArgs[2] -replace '/', '\' }
        } catch {}
    }
    if ($Silent) {
        if ($projectsRoot) { & $deployScript -Silent -ProjectsRoot $projectsRoot } else { & $deployScript -Silent }
    } else {
        if ($projectsRoot) { & $deployScript -ProjectsRoot $projectsRoot } else { & $deployScript }
    }
}
