# Changelog

Todos los cambios notables siguen [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

---

## [Unreleased]

### Agregado
- `doctor.ps1` — validación completa de la instalación (git, Node.js, Claude Code, Codex, engram, MCPs, archivos)
- `uninstall.ps1` — desinstalación limpia con confirmación explícita para borrar memoria
- `Backup-File` en `setup.ps1` — backups timestamped antes de sobreescribir CLAUDE.md y settings.json
- `.gitattributes` — normalización de line endings por tipo de archivo
- `tests/setup.validation.tests.ps1` — tests Pester para validar el setup
- Sección Codex en `setup.ps1`: registry, memoria, permisos `[approvals]`, hook de commits
- README reescrito — Quick Start, Requisitos, Seguridad, Troubleshooting, formato de registry, convención MCPs, skills, limitaciones Claude Code vs Codex, Roadmap

### Cambiado
- `setup.ps1` — removidos filtros `if: "Bash(git *)"` de PostToolUse (bloqueaban los hooks)
- Hook Stop — agente Engram ignora `stop_hook_active`, usa solo herramientas nativas (sin MCP)
- Hook Stop — detecta proyecto activo por rutas de archivos en el transcript (no solo por menciones)
- `sync.ps1` — ya no genera duplicados en MEMORY.md (removida lógica de append con matching impreciso)
- MEMORY.md — de-duplicado (estaba triplicado por bug en setup.ps1)

### Eliminado
- Toda la integración con Obsidian — hooks, parámetros `$UseObsidian`, sección del vault en CLAUDE.md
- Filtros `if` en hooks PostToolUse — causaban que los hooks no dispararan
- Archivos obsoletos: `settings-hook.json`, `mcp-config.json`, `mcp-secrets-guide.md`, `hooks/on-session-stop.ps1`, `tmp/hook-test.txt`

---

## [1.0.0] — 2026-03-01

### Inicial
- `setup.ps1` — instalador para Claude Code y Codex
- `auto-update.ps1` — sincronización automática al iniciar sesión
- `sync.ps1` — copia memoria local de vuelta al repo
- Skills: 27 comandos para Angular, NestJS, .NET, Next.js, Jira, Slack, etc.
- Sistema de memoria Engram con archivos `memory/*.md`
- MCPs: GitHub, memory, PostgreSQL, SQL Server (auto-detectados desde `mcp.env`)
- Hook `on-git-commit.ps1` — registra commits en `changes-log.md`
- Hook Stop — agente Engram analiza sesión y actualiza memoria

---

> **Nota sobre LICENSE**: Este repo es de configuración personal. No tiene licencia pública — todo el contenido es propietario. Si fork, hacelo tuyo desde el principio.
