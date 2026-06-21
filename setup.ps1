# setup.ps1 — Instalar claude-config en este dispositivo
# Detecta automáticamente Claude Code y/o Codex e instala en ambos
#
# Uso:
#   .\setup.ps1                          → auto-detecta herramientas
#   .\setup.ps1 -Tool claude             → solo Claude Code
#   .\setup.ps1 -Tool codex              → solo Codex
#   .\setup.ps1 -Tool both               → ambos
#   .\setup.ps1 -ProjectsRoot "D:\Proyectos"

param(
    [string]$ProjectsRoot = "$env:USERPROFILE\OneDrive\Documentos\Proyectos",
    [ValidateSet("auto","claude","codex","both")]
    [string]$Tool = "auto"
)

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeHome   = "$env:USERPROFILE\.claude"
$CodexHome    = "$env:USERPROFILE\.codex"
$Username     = $env:USERNAME

Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      claude-config — Setup           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "Usuario:    $Username"
Write-Host "Proyectos:  $ProjectsRoot"
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# FASE 0 — Leer mcp.env y cargar env vars
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "[ 0 ] Cargando tokens desde mcp.env..." -ForegroundColor Yellow
$EnvFile = "$ScriptDir\mcp.env"
$envVars = @{}   # hashtable con todas las vars reales del archivo (sin placeholders)
if (Test-Path $EnvFile) {
    $loaded = 0
    Get-Content $EnvFile | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' } | ForEach-Object {
        $parts = $_ -split '=', 2
        $key   = $parts[0].Trim()
        $value = $parts[1].Trim()
        if ($key -and $value -notmatch 'your_|_here$|password$') {
            [System.Environment]::SetEnvironmentVariable($key, $value, "User")
            $envVars[$key] = $value
            $loaded++
        }
    }
    Write-Host "     OK → $loaded variable(s) cargadas" -ForegroundColor Green
} else {
    Write-Host "     mcp.env no encontrado — copia mcp.env.example → mcp.env y llena los valores" -ForegroundColor DarkYellow
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 1 — Detectar herramientas instaladas
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[ 1 ] Detectando herramientas instaladas..." -ForegroundColor Yellow

$hasClaude = (Test-Path $ClaudeHome) -or (Get-Command claude -ErrorAction SilentlyContinue)
$hasCodex  = (Test-Path $CodexHome)  -or (Get-Command codex  -ErrorAction SilentlyContinue)
$hasEngram = [bool](Get-Command engram -ErrorAction SilentlyContinue)

if ($Tool -eq "auto") {
    $installClaude = $hasClaude
    $installCodex  = $hasCodex
} else {
    $installClaude = ($Tool -eq "claude" -or $Tool -eq "both")
    $installCodex  = ($Tool -eq "codex"  -or $Tool -eq "both")
}

Write-Host "     Claude Code : $(if ($hasClaude) { '✓ detectado' } else { '✗ no encontrado' })"
Write-Host "     Codex       : $(if ($hasCodex)  { '✓ detectado' } else { '✗ no encontrado' })"
Write-Host "     Engram      : $(if ($hasEngram) { '✓ detectado' } else { '✗ no encontrado' })"
Write-Host ""
Write-Host "     Instalar en: $(if ($installClaude -and $installCodex) { 'Claude Code + Codex' } elseif ($installClaude) { 'Claude Code' } elseif ($installCodex) { 'Codex' } else { 'ninguno detectado — usa -Tool claude|codex|both' })" -ForegroundColor Cyan

if (-not $installClaude -and -not $installCodex) {
    Write-Host ""
    Write-Host "No se detectó ninguna herramienta. Usa -Tool claude, -Tool codex o -Tool both" -ForegroundColor Red
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 2 — Instalar en CLAUDE CODE
# ─────────────────────────────────────────────────────────────────────────────
if ($installClaude) {
    Write-Host ""
    Write-Host "┌─ Claude Code ───────────────────────────────┐" -ForegroundColor Blue
    New-Item -ItemType Directory -Force $ClaudeHome | Out-Null

    # Commands (skills)
    Write-Host "  Instalando commands..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force "$ClaudeHome\commands" | Out-Null
    Copy-Item "$ScriptDir\commands\*.md" "$ClaudeHome\commands\" -Force
    # Limpiar skills/ obsoleta
    Get-ChildItem "$ClaudeHome\skills" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  OK → $((Get-ChildItem "$ScriptDir\commands\*.md").Count) commands" -ForegroundColor Green

    # CLAUDE.md global
    Copy-Item "$ScriptDir\CLAUDE.md" "$ClaudeHome\CLAUDE.md" -Force
    Write-Host "  OK → CLAUDE.md" -ForegroundColor Green

    # Registry de proyectos
    Copy-Item "$ScriptDir\projects-registry.md" "$ClaudeHome\projects-registry.md" -Force
    Write-Host "  OK → projects-registry.md" -ForegroundColor Green

    # Memoria (engram)
    $EncodedHome = $env:USERPROFILE -replace "^([A-Za-z]):\\", '$1--' -replace "\\", "-"
    $MemoryPath  = "$ClaudeHome\projects\$EncodedHome\memory"
    New-Item -ItemType Directory -Force $MemoryPath | Out-Null
    Copy-Item "$ScriptDir\memory\*.md" "$MemoryPath\" -Force
    Write-Host "  OK → $((Get-ChildItem "$ScriptDir\memory\*.md").Count) archivos de memoria" -ForegroundColor Green

    # MEMORY.md
    $MemIdx    = "$MemoryPath\MEMORY.md"
    $Entries   = @(
        "- [Token economy + modelos](feedback-token-economy.md) — Haiku para git ops, Sonnet default, Opus solo con consulta previa",
        "- [Perfil de usuario](user-profile.md) — Naidelyn, dev full-stack, 6 clientes, 58 repos",
        "- [Log de cambios](changes-log.md) — historial de commits y PRs por proyecto",
        "- [Jira cithn.atlassian.net](reference-jira.md) — cloudId + mapping alias→key",
        "- [Config claude-config](setup-claude-config.md) — Repo portable de configuración",
        "- [Proyectos YALO](projects-yalo.md) — 22 subproyectos POS/pagos, aliases ``yalo *``",
        "- [Proyectos La Bodega](projects-labodega.md) — 10 subproyectos ecommerce, aliases ``bodega *``",
        "- [Proyectos CORINSA](projects-corinsa.md) — 7 subproyectos BI/CPA, aliases ``corinsa *`` y ``cpa *``",
        "- [Proyectos Ultimate Labs](projects-ultimatelabs.md) — 6 subproyectos labs, aliases ``ult *``",
        "- [Proyectos EMSULA + NAI](projects-otros.md) — 12 subproyectos médicos y personales",
        "- [Workspaces](projects-workspaces.md) — Grupos de repos para trabajo simultáneo con git sync"
    )
    $existing = if (Test-Path $MemIdx) { Get-Content $MemIdx } else { @() }
    $toAdd    = $Entries | Where-Object { $existing -notcontains $_ }
    if (-not (Test-Path $MemIdx)) { "# Memory Index" | Set-Content $MemIdx -Encoding utf8 }
    if ($toAdd) { $toAdd -join "`n" | Add-Content $MemIdx -Encoding utf8 }
    Write-Host "  OK → MEMORY.md actualizado" -ForegroundColor Green

    # mcp.json — DBs auto-detectadas desde mcp.env, siempre reescribir
    $mcpJsonPath = "$ClaudeHome\mcp.json"
    $dbServers = [ordered]@{}
    foreach ($key in ($envVars.Keys | Sort-Object)) {
        if ($key -match '^(.+)_DEV$') {
            $mcpName = "pg-$($matches[1].ToLower() -replace '_','-')"
            $dbServers[$mcpName] = [PSCustomObject]@{ command="powershell"; args=@("-Command","npx -y mcp-server-postgres `$env:$key") }
        } elseif ($key -match '^(.+)_SS$') {
            $mcpName = "ss-$($matches[1].ToLower() -replace '_','-')"
            $dbServers[$mcpName] = [PSCustomObject]@{ command="powershell"; args=@("-Command","npx -y mssql-mcp `$env:$key") }
        }
    }
    $mcpJsonObj = [PSCustomObject]@{ mcpServers = [PSCustomObject]@{} }
    foreach ($name in $dbServers.Keys) {
        $mcpJsonObj.mcpServers | Add-Member -NotePropertyName $name -NotePropertyValue $dbServers[$name]
    }
    $mcpJsonObj | ConvertTo-Json -Depth 5 | Set-Content $mcpJsonPath -Encoding utf8
    Write-Host "  OK → mcp.json reescrito con $($dbServers.Count) DB(s) detectadas desde mcp.env" -ForegroundColor Green

    # NPM packages de MCPs
    Write-Host "  Instalando paquetes MCP..." -ForegroundColor Yellow
    npm install -g @modelcontextprotocol/server-github @modelcontextprotocol/server-filesystem @modelcontextprotocol/server-memory mcp-server-postgres mssql-mcp --silent 2>$null
    Write-Host "  OK → paquetes MCP instalados" -ForegroundColor Green

    # settings.json — MCPs + permiso Write
    $SettingsPath = "$ClaudeHome\settings.json"
    if (Test-Path $SettingsPath) {
        $cfg = Get-Content $SettingsPath -Raw | ConvertFrom-Json
    } else {
        $cfg = [PSCustomObject]@{ permissions = [PSCustomObject]@{ defaultMode = "dontAsk"; allow = @() } }
    }
    $writePermission = "Write($SettingsPath)"
    if ($cfg.permissions.allow -notcontains $writePermission) {
        $cfg.permissions.allow += $writePermission
    }
    # Plugins — siempre asegurarse de que estén habilitados
    $pluginsToEnable = @(
        "frontend-design@claude-plugins-official",
        "superpowers@claude-plugins-official",
        "code-review@claude-plugins-official",
        "context7@claude-plugins-official",
        "skill-creator@claude-plugins-official",
        "figma@claude-plugins-official",
        "playwright@claude-plugins-official",
        "typescript@claude-plugins-official",
        "csharp@claude-plugins-official"
    )
    if (-not $cfg.PSObject.Properties['enabledPlugins']) {
        $pluginsObj = [PSCustomObject]@{}
        foreach ($p in $pluginsToEnable) { $pluginsObj | Add-Member -NotePropertyName $p -NotePropertyValue $true }
        $cfg | Add-Member -NotePropertyName enabledPlugins -NotePropertyValue $pluginsObj -Force
    } else {
        foreach ($p in $pluginsToEnable) {
            if (-not $cfg.enabledPlugins.PSObject.Properties[$p]) {
                $cfg.enabledPlugins | Add-Member -NotePropertyName $p -NotePropertyValue $true
            }
        }
    }
    $cfg | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding utf8
    Write-Host "  OK → plugins habilitados en settings.json" -ForegroundColor Green

    if (-not $cfg.PSObject.Properties['mcpServers']) {
        $proyectosPath = ($ProjectsRoot -replace '\\','/')
        $claudePathFwd = ($ClaudeHome -replace '\\','/')
        $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([PSCustomObject]@{
            github          = [PSCustomObject]@{ command="npx"; args=@("-y","@modelcontextprotocol/server-github"); shell="powershell" }
            filesystem      = [PSCustomObject]@{ command="npx"; args=@("-y","@modelcontextprotocol/server-filesystem",$proyectosPath,"$($env:USERPROFILE -replace '\\','/')/OneDrive/Documentos/Obsidian",$claudePathFwd); shell="powershell" }
            memory          = [PSCustomObject]@{ command="npx"; args=@("-y","@modelcontextprotocol/server-memory"); shell="powershell" }
        }) -Force
        $cfg | Add-Member -NotePropertyName disabledMcpjsonServers -NotePropertyValue @(
            "pg-labodega","pg-yalo","pg-corinsa","pg-ultimatelabs","pg-emsula",
            "ss-corinsa","ss-emsula","ss-yalo"
        ) -Force
        if ($hasEngram) {
            $cfg.mcpServers | Add-Member -NotePropertyName engram -NotePropertyValue ([PSCustomObject]@{ command="engram"; args=@("mcp") }) -Force
        }
        $cfg | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding utf8
        Write-Host "  OK → settings.json con MCPs configurados" -ForegroundColor Green
    } else {
        Write-Host "  OK → settings.json ya tenía MCPs" -ForegroundColor Green
    }
    Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Blue
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 3 — Instalar en CODEX
# ─────────────────────────────────────────────────────────────────────────────
if ($installCodex) {
    Write-Host ""
    Write-Host "┌─ Codex ─────────────────────────────────────┐" -ForegroundColor Magenta
    New-Item -ItemType Directory -Force $CodexHome | Out-Null

    # Skills — convertir commands/*.md → ~/.codex/skills/<name>/SKILL.md + openai.yaml
    Write-Host "  Instalando skills + agentes Codex..." -ForegroundColor Yellow
    $skillCount = 0
    Get-ChildItem "$ScriptDir\commands\*.md" | ForEach-Object {
        $skillName    = $_.BaseName
        $skillDir     = "$CodexHome\skills\$skillName"
        $agentsDir    = "$skillDir\agents"
        $skillContent = Get-Content $_.FullName -Encoding utf8 -Raw

        # Extraer description del frontmatter
        $description = $skillName   # fallback al nombre del skill
        if ($skillContent -match '(?s)^---\s*\r?\n.*?description:\s*(.+?)\r?\n.*?---') {
            $description = $matches[1].Trim()
        }

        # Nombre para mostrar — PascalCase del filename
        $displayName = (Get-Culture).TextInfo.ToTitleCase($skillName.Replace('-', ' '))

        # Crear estructura de directorios
        New-Item -ItemType Directory -Force $skillDir   | Out-Null
        New-Item -ItemType Directory -Force $agentsDir  | Out-Null

        # Copiar SKILL.md
        Copy-Item $_.FullName "$skillDir\SKILL.md" -Force

        # Generar openai.yaml — descripción en inglés simple para evitar problemas de encoding
        $shortDesc     = "Use this skill for $skillName tasks and code generation."
        $defaultPrompt = "Activate the $skillName skill to help with $skillName-related tasks, code generation, and patterns."
        $yamlContent = @"
interface:
  display_name: "$displayName"
  short_description: "$shortDesc"
  default_prompt: "$defaultPrompt"
"@
        $yamlContent | Set-Content "$agentsDir\openai.yaml" -Encoding utf8
        $skillCount++
    }
    Write-Host "  OK → $skillCount skills + openai.yaml instalados en ~/.codex/skills/" -ForegroundColor Green

    # Instructions (equivalente a CLAUDE.md) — adaptar sintaxis /cmd → $cmd para Codex
    # IMPORTANTE: usar [System.IO.File]::ReadAllText con UTF-8 explícito para respetar tildes y ñ
    $instrFile     = "$CodexHome\engram-instructions.md"
    $marker        = "<!-- nai-rules-start -->"
    $instrExisting = if (Test-Path $instrFile) {
        [System.IO.File]::ReadAllText($instrFile, [System.Text.Encoding]::UTF8)
    } else { "" }

    $claudeContent = [System.IO.File]::ReadAllText("$ScriptDir\CLAUDE.md", [System.Text.Encoding]::UTF8)
    $codexContent  = $claudeContent -replace '`/([a-z\-]+)`', '`$$1`'
    $newBlock      = "$marker`n$codexContent`n<!-- nai-rules-end -->"

    if ($instrExisting -notmatch [regex]::Escape($marker)) {
        $instrExisting += "`n`n$newBlock"
    } else {
        $instrExisting = $instrExisting -replace "(?s)$([regex]::Escape($marker)).*?<!-- nai-rules-end -->", $newBlock
    }

    [System.IO.File]::WriteAllText($instrFile, $instrExisting, [System.Text.Encoding]::UTF8)
    Write-Host "  OK → engram-instructions.md actualizado (UTF-8 correcto)" -ForegroundColor Green

    # Expresiones hondureñas — copiar a ~/.codex/ para que Codex las tenga disponibles
    if (Test-Path "$ScriptDir\expressions.md") {
        Copy-Item "$ScriptDir\expressions.md" "$CodexHome\expressions.md" -Force
        Write-Host "  OK → expressions.md copiado a ~/.codex/" -ForegroundColor Green
    }

    # MCPs en config.toml — reemplazar TODAS las secciones [mcp_servers.*] con las canónicas
    Write-Host "  Configurando MCPs en config.toml..." -ForegroundColor Yellow
    $configPath = "$CodexHome\config.toml"
    $configRaw  = if (Test-Path $configPath) { Get-Content $configPath -Raw } else { "" }

    # Borrar todos los bloques [mcp_servers.*] existentes (incluyendo sus claves hasta el siguiente [)
    $lines = $configRaw -split "`n"
    $inMcpSection = $false
    $cleanedLines = @()
    foreach ($line in $lines) {
        if ($line -match '^\[mcp_servers\.[^\]]+\]') {
            $inMcpSection = $true
        } elseif ($line -match '^\[') {
            $inMcpSection = $false
        }
        if (-not $inMcpSection) { $cleanedLines += $line }
    }
    $configRaw = ($cleanedLines -join "`n").TrimEnd()

    # MCPs fijos — solo los que no dependen de mcp.env
    $mcpEntries = [ordered]@{
        "engram"     = "command = `"engram`"`nargs = [`"mcp`"]"
        "figma"      = "url = `"https://mcp.figma.com/mcp`""
        "resend"     = if ($envVars["RESEND_API_KEY"]) { "command = `"npx`"`nargs = [`"-y`", `"resend-mcp`"]`nenv = { RESEND_API_KEY = `"$($envVars['RESEND_API_KEY'])`" }" } else { $null }
        "github"     = "command = `"npx`"`nargs = [`"-y`", `"@modelcontextprotocol/server-github`"]"
        "filesystem" = "command = `"npx`"`nargs = [`"-y`", `"@modelcontextprotocol/server-filesystem`", `"$($ProjectsRoot -replace '\\','/')`", `"$($CodexHome -replace '\\','/')`"]"
    }

    # engram solo si está disponible; resend solo si RESEND_API_KEY existe en mcp.env
    if (-not $hasEngram) { $mcpEntries.Remove("engram") }
    $nullKeys = @($mcpEntries.Keys | Where-Object { $null -eq $mcpEntries[$_] })
    foreach ($k in $nullKeys) { $mcpEntries.Remove($k) }

    # MCPs de DB — detectados automáticamente desde mcp.env
    # Convención: NOMBRE_DEV → pg-nombre (postgres), NOMBRE_SS → ss-nombre (SQL Server)
    $dbCount = 0
    foreach ($key in ($envVars.Keys | Sort-Object)) {
        if ($key -match '^(.+)_DEV$') {
            $mcpName = "pg-$($matches[1].ToLower() -replace '_','-')"
            $mcpEntries[$mcpName] = "command = `"powershell`"`nargs = [`"-Command`", `"npx -y mcp-server-postgres `$env:$key`"]`nstartup_timeout_sec = 90"
            $dbCount++
        } elseif ($key -match '^(.+)_SS$') {
            $mcpName = "ss-$($matches[1].ToLower() -replace '_','-')"
            $mcpEntries[$mcpName] = "command = `"powershell`"`nargs = [`"-Command`", `"npx -y mssql-mcp `$env:$key`"]`nstartup_timeout_sec = 90"
            $dbCount++
        }
    }
    Write-Host "  $dbCount MCP(s) de DB detectados desde mcp.env" -ForegroundColor DarkGray

    foreach ($name in $mcpEntries.Keys) {
        $configRaw += "`n`n[mcp_servers.$name]`n$($mcpEntries[$name])"
    }
    $configRaw | Set-Content $configPath -Encoding utf8
    Write-Host "  OK → $($mcpEntries.Count) MCPs escritos (reemplazando configuración anterior)" -ForegroundColor Green

    # Plugins de Codex
    Write-Host "  Habilitando plugins de Codex..." -ForegroundColor Yellow
    $configRaw = Get-Content $configPath -Raw
    $codexPlugins = @(
        "codex-security@openai-curated",
        "slack@openai-curated"
    )
    $pluginsAdded = 0
    foreach ($p in $codexPlugins) {
        $section = "[plugins.`"$p`"]"
        if ($configRaw -notmatch [regex]::Escape($section)) {
            $configRaw += "`n`n$section`nenabled = true"
            $pluginsAdded++
        }
    }
    $configRaw | Set-Content $configPath -Encoding utf8
    Write-Host "  OK → $pluginsAdded plugin(s) agregados (Slack requiere auth manual la primera vez)" -ForegroundColor Green

    Write-Host "└─────────────────────────────────────────────┘" -ForegroundColor Magenta
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 4 — Engram compartido (si está disponible)
# ─────────────────────────────────────────────────────────────────────────────
if ($hasEngram -and $installClaude -and $installCodex) {
    Write-Host ""
    Write-Host "[ 4 ] Engram detectado — memoria compartida entre Claude Code y Codex ✓" -ForegroundColor Green
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 5 — Auto-update: hook en Claude Code + tareas programadas en Windows
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[ 5 ] Configurando auto-update..." -ForegroundColor Yellow

$autoUpdateScript = "$ScriptDir\auto-update.ps1"

# ── Claude Code: SessionStart hook ──────────────────────────────────────────
if ($installClaude) {
    $SettingsPath = "$ClaudeHome\settings.json"
    $cfg = Get-Content $SettingsPath -Raw | ConvertFrom-Json

    $hookCmd = "& '$autoUpdateScript' -Tool claude -Silent"

    # Desplegar script de hook a ~/.claude/hooks/
    $hooksDir = "$ClaudeHome\hooks"
    New-Item -ItemType Directory -Force $hooksDir | Out-Null
    Copy-Item "$ScriptDir\hooks\on-git-commit.ps1" "$hooksDir\on-git-commit.ps1" -Force

    $commitScript = "$hooksDir\on-git-commit.ps1"

    $hooksObj = [PSCustomObject]@{
        PostToolUse = @(
            [PSCustomObject]@{
                matcher = "Bash"
                hooks   = @(
                    [PSCustomObject]@{
                        type          = "command"
                        if            = "Bash(git *)"
                        shell         = "powershell"
                        command       = "& '$commitScript'"
                        timeout       = 15
                        statusMessage = "Guardando en Obsidian..."
                    }
                )
            },
            [PSCustomObject]@{
                matcher = "PowerShell"
                hooks   = @(
                    [PSCustomObject]@{
                        type          = "command"
                        if            = "PowerShell(git *)"
                        shell         = "powershell"
                        command       = "& '$commitScript'"
                        timeout       = 15
                        statusMessage = "Guardando en Obsidian..."
                    }
                )
            }
        )
        SessionStart = @(
            [PSCustomObject]@{
                hooks = @(
                    [PSCustomObject]@{
                        type    = "command"
                        command = $hookCmd
                        shell   = "powershell"
                        async   = $true
                    }
                )
            }
        )
    }
    $cfg | Add-Member -NotePropertyName hooks -NotePropertyValue $hooksObj -Force
    $cfg | ConvertTo-Json -Depth 15 | Set-Content $SettingsPath -Encoding utf8
    Write-Host "  OK → hooks configurados (SessionStart auto-update + PostToolUse commit→Obsidian)" -ForegroundColor Green
}

# ── Windows Task Scheduler: diario + al inicio de sesión ────────────────────
$toolArg = if ($installClaude -and $installCodex) { "both" } elseif ($installClaude) { "claude" } else { "codex" }

# Tarea diaria a las 8am
$dailyAction  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -File `"$autoUpdateScript`" -Tool $toolArg -Silent"
$dailyTrigger = New-ScheduledTaskTrigger -Daily -At "08:00"
$dailySettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -StartWhenAvailable

Register-ScheduledTask `
    -TaskName   "AgentAIConfig-DailyUpdate" `
    -Action     $dailyAction `
    -Trigger    $dailyTrigger `
    -Settings   $dailySettings `
    -Description "Actualiza agent-ai-config diariamente a las 8am" `
    -Force | Out-Null
Write-Host "  OK → Tarea diaria registrada (08:00 AM)" -ForegroundColor Green

# Tarea al inicio de sesión de Windows (para Codex y como respaldo)
$logonAction  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -File `"$autoUpdateScript`" -Tool $toolArg -Silent"
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$logonSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 3) -StartWhenAvailable

Register-ScheduledTask `
    -TaskName   "AgentAIConfig-OnLogon" `
    -Action     $logonAction `
    -Trigger    $logonTrigger `
    -Settings   $logonSettings `
    -Description "Actualiza agent-ai-config al iniciar sesión en Windows" `
    -Force | Out-Null
Write-Host "  OK → Tarea al inicio de sesión registrada" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# RESUMEN
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Instalación completa ✓          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
if ($installClaude) { Write-Host "  Claude Code → ~/.claude/commands/ | ~/.claude/settings.json" -ForegroundColor Blue }
if ($installCodex)  { Write-Host "  Codex       → ~/.codex/skills/    | ~/.codex/config.toml"    -ForegroundColor Magenta }
Write-Host ""
Write-Host "  Próximos pasos:"
if (-not (Test-Path "$ScriptDir\mcp.env")) {
    Write-Host "  1. Copia mcp.env.example → mcp.env y llena los tokens/conexiones" -ForegroundColor Yellow
    Write-Host "  2. Vuelve a correr .\setup.ps1"
    Write-Host "  3. Reinicia Claude Code / Codex"
} else {
    Write-Host "  1. Reinicia Claude Code y/o Codex"
    Write-Host "  2. Usa /proyecto para ver todos los proyectos"
}
Write-Host ""
