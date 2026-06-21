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
$yaloSkillsRepo = "$env:USERPROFILE\OneDrive\Documentos\Proyectos\YALO\YALO-SKILLS"
$yaloDir        = "$env:USERPROFILE\OneDrive\Documentos\Proyectos\YALO"
$claudeHome     = "$env:USERPROFILE\.claude"
$codexHome      = "$env:USERPROFILE\.codex"
$skills         = "yalo-components", "yalo-database"

if (-not (Test-Path "$yaloSkillsRepo\.git")) {
    if (-not $Silent) { Write-Host "[YALO-SKILLS] Clonando repo..." -ForegroundColor Yellow }
    git -C $yaloDir clone https://github.com/Yalo-Technologies/YALO-SKILLS.git --quiet 2>$null
    $deploySkills = $true
} else {
    git -C $yaloSkillsRepo fetch origin --quiet 2>$null
    $yaloBehind = (git -C $yaloSkillsRepo rev-list "HEAD..origin/master" --count 2>$null).Trim()
    if ([int]$yaloBehind -gt 0) {
        git -C $yaloSkillsRepo pull origin master --quiet 2>$null
        if (-not $Silent) { Write-Host "[YALO-SKILLS] $yaloBehind commit(s) nuevos - redesplegando..." -ForegroundColor Cyan }
        $deploySkills = $true
    } else {
        $deploySkills = $false
        if (-not $Silent) { Write-Host "[YALO-SKILLS] Al dia" -ForegroundColor DarkGray }
    }
}

if ($deploySkills) {
    foreach ($skill in $skills) {
        $skillMd = Join-Path $yaloSkillsRepo "$skill\SKILL.md"
        if (-not (Test-Path $skillMd)) { continue }

        # Claude Code: copiar SKILL.md reescribiendo paths de referencias a absolutos
        $content   = [System.IO.File]::ReadAllText($skillMd, [System.Text.Encoding]::UTF8)
        $refsAbs   = ($yaloSkillsRepo -replace "\\", "/") + "/$skill/references/"
        $skillNorm = $skill -replace "-", ""
        $content   = $content -replace "references/", $refsAbs
        $content   = $content -replace "skills/$skill/references/", $refsAbs
        $content   = $content -replace "skills/${skillNorm}/references/", $refsAbs
        $scriptAbs = ($yaloSkillsRepo -replace "\\", "/") + "/$skill/"
        $content   = $content -replace "~/.agents/skills/$skill/", $scriptAbs
        $content   = $content -replace "~/.agents/skills/${skillNorm}/", $scriptAbs
        [System.IO.File]::WriteAllText((Join-Path $claudeHome "commands\$skill.md"), $content, [System.Text.Encoding]::UTF8)

        # Codex: copiar directorio completo + openai.yaml
        $codexSkillDir = Join-Path $codexHome "skills\$skill"
        New-Item -ItemType Directory -Force $codexSkillDir | Out-Null
        Get-ChildItem (Join-Path $yaloSkillsRepo $skill) | Copy-Item -Destination $codexSkillDir -Recurse -Force
        $agentsDir = Join-Path $codexSkillDir "agents"
        New-Item -ItemType Directory -Force $agentsDir | Out-Null
        $yamlLines = @(
            "interface:",
            "  display_name: $skill",
            "  short_description: Yalo skill $skill",
            "  default_prompt: Activate the $skill skill."
        )
        [System.IO.File]::WriteAllLines((Join-Path $agentsDir "openai.yaml"), $yamlLines, [System.Text.Encoding]::UTF8)
    }
    if (-not $Silent) {
        Write-Host ("[YALO-SKILLS] Skills actualizados: " + [string]::Join(", ", $skills)) -ForegroundColor Green
    }
}
