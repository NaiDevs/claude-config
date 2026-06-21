# yalo-skills-deploy.ps1 - Clona/actualiza YALO-SKILLS y despliega TODO en Claude Code y Codex
# Despliega yalo-components y yalo-database (ignora yalo-turnos y yalo-turnos-cli)
param(
    [switch]$Silent,
    [switch]$Force,        # forzar redespliegue aunque no haya cambios
    [string]$ProjectsRoot  # carpeta raiz de proyectos; si no se pasa, usa la del usuario actual
)

$IsWin   = ($env:OS -eq "Windows_NT") -or (-not $PSVersionTable.Platform)
$HomeDir = if ($IsWin) { $env:USERPROFILE } else { $HOME }

# Determinar dónde clonar: $ProjectsRoot\YALO\YALO-SKILLS
if (-not $ProjectsRoot) {
    $ProjectsRoot = if ($IsWin) { "$HomeDir\OneDrive\Documentos\Proyectos" } else { "$HomeDir/OneDrive/Documentos/Proyectos" }
}
$yaloDir        = Join-Path $ProjectsRoot "YALO"
$yaloSkillsRepo = Join-Path $yaloDir "YALO-SKILLS"
$claudeHome     = Join-Path $HomeDir ".claude"
$codexHome      = Join-Path $HomeDir ".codex"
$skills         = @("yalo-components", "yalo-database")

# Clonar si no existe
if (-not (Test-Path (Join-Path $yaloSkillsRepo ".git"))) {
    if (-not $Silent) { Write-Host "  Clonando YALO-SKILLS..." -ForegroundColor Yellow }
    # Crear directorio padre si no existe
    if (-not (Test-Path $yaloDir)) {
        New-Item -ItemType Directory -Force $yaloDir | Out-Null
    }
    git -C $yaloDir clone https://github.com/Yalo-Technologies/YALO-SKILLS.git --quiet 2>$null
    if (-not (Test-Path (Join-Path $yaloSkillsRepo ".git"))) {
        Write-Host "  ERROR: no se pudo clonar YALO-SKILLS" -ForegroundColor Red
        Write-Host "  Posibles causas:" -ForegroundColor Yellow
        Write-Host "    - Sin acceso a internet" -ForegroundColor DarkYellow
        Write-Host "    - Repositorio privado (pedi acceso a tu equipo YALO)" -ForegroundColor DarkYellow
        Write-Host "    - git no esta en el PATH" -ForegroundColor DarkYellow
        Write-Host "  Corra manualmente: git clone https://github.com/Yalo-Technologies/YALO-SKILLS.git $yaloSkillsRepo" -ForegroundColor DarkYellow
        exit 1
    }
    $deploy = $true
} else {
    # Pull y verificar si hay cambios
    git -C $yaloSkillsRepo fetch origin --quiet 2>$null
    $behind = (git -C $yaloSkillsRepo rev-list "HEAD..origin/master" --count 2>$null).Trim()
    if ([int]$behind -gt 0) {
        git -C $yaloSkillsRepo pull origin master --quiet 2>$null
        if (-not $Silent) { Write-Host "  YALO-SKILLS: $behind commit(s) nuevos" -ForegroundColor Cyan }
        $deploy = $true
    } else {
        $deploy = $Force.IsPresent
        if (-not $Silent -and -not $deploy) { Write-Host "  YALO-SKILLS: al dia" -ForegroundColor DarkGray }
    }
}

if (-not $deploy) { exit 0 }

# Desplegar cada skill
foreach ($skill in $skills) {
    $skillDir = Join-Path $yaloSkillsRepo $skill
    $skillMd  = Join-Path $skillDir "SKILL.md"
    if (-not (Test-Path $skillMd)) {
        if (-not $Silent) { Write-Host "  SKILL.md no encontrado: $skillDir" -ForegroundColor Yellow }
        continue
    }

    # ── Claude Code ────────────────────────────────────────────────────────
    # 1. Copiar TODO el directorio del skill a ~/.claude/skills/<skill>/
    $claudeSkillDir = Join-Path $claudeHome "skills\$skill"
    if (Test-Path $claudeSkillDir) { Remove-Item $claudeSkillDir -Recurse -Force }
    New-Item -ItemType Directory -Force $claudeSkillDir | Out-Null
    Get-ChildItem $skillDir | Copy-Item -Destination $claudeSkillDir -Recurse -Force

    # 2. Copiar SKILL.md como command con paths reescritos a ~/.claude/skills/<skill>/
    $content    = [System.IO.File]::ReadAllText($skillMd, [System.Text.Encoding]::UTF8)
    $claudeBase = ($claudeSkillDir -replace "\\", "/") + "/"
    $repoBase   = ($skillDir -replace "\\", "/") + "/"

    # Reescribir referencias relativas al skill (varios patrones que usa YALO-SKILLS)
    $content = $content -replace "(?i)(?<![:/])references/", ($claudeBase + "references/")
    $content = $content -replace "(?i)(?<![:/])scripts/", ($claudeBase + "scripts/")
    $skillNorm = $skill -replace "-", ""
    $content = $content -replace "skills/$skill/", $claudeBase
    $content = $content -replace "skills/${skillNorm}/", $claudeBase
    $content = $content -replace "~/.agents/skills/$skill/", $claudeBase
    $content = $content -replace "~/.agents/skills/${skillNorm}/", $claudeBase

    [System.IO.File]::WriteAllText(
        (Join-Path $claudeHome "commands\$skill.md"),
        $content,
        [System.Text.Encoding]::UTF8
    )

    # ── Codex ───────────────────────────────────────────────────────────────
    # Copiar TODO el directorio a ~/.codex/skills/<skill>/
    $codexSkillDir = Join-Path $codexHome "skills\$skill"
    if (Test-Path $codexSkillDir) { Remove-Item $codexSkillDir -Recurse -Force }
    New-Item -ItemType Directory -Force $codexSkillDir | Out-Null
    Get-ChildItem $skillDir | Copy-Item -Destination $codexSkillDir -Recurse -Force

    # Generar agents/openai.yaml para Codex
    $agentsDir = Join-Path $codexSkillDir "agents"
    New-Item -ItemType Directory -Force $agentsDir | Out-Null
    $yamlLines = @(
        "interface:",
        "  display_name: $skill",
        "  short_description: Yalo skill - $skill",
        "  default_prompt: Activate the $skill skill."
    )
    [System.IO.File]::WriteAllLines(
        (Join-Path $agentsDir "openai.yaml"),
        $yamlLines,
        [System.Text.Encoding]::UTF8
    )

    if (-not $Silent) {
        $fileCount = (Get-ChildItem $skillDir -Recurse -File).Count
        Write-Host "  OK $skill ($fileCount archivos desplegados en Claude Code + Codex)" -ForegroundColor Green
    }
}
