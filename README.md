# agent-ai-config

Configuración personal para **Claude Code** y/o **Codex** — proyectos, aliases, workspaces, skills, MCPs y memoria persistente (Engram).

Un solo repo, un solo `setup.ps1`, compatible con ambas herramientas.

---

## Contenido del repo

| Archivo/Carpeta | Para qué sirve |
|---|---|
| `CLAUDE.md` | Reglas siempre activas + auto-activación de skills |
| `projects-registry.md` | Aliases de proyectos, Jira keys y workspaces |
| `commands/*.md` | Skills (`/angular`, `/nestjs`, `/dotnet`, `/commit`, etc.) |
| `memory/*.md` | Memoria persistente Engram — proyectos, decisiones, cambios |
| `hooks/on-git-commit.ps1` | Hook PostToolUse — guarda commits en Engram al hacer `git commit` |
| `mcp.env.example` | Plantilla de tokens y conexiones (copiar a `mcp.env`) |
| `setup.ps1` | Instalador — detecta Claude Code y/o Codex automáticamente |
| `auto-update.ps1` | Sincroniza este repo en cada inicio de sesión |

---

## Instalación en nuevo dispositivo

### Paso 1 — Clonar el repo

```powershell
git clone https://github.com/NaiDevs/agent-ai-config.git <ruta-destino>
cd <ruta-destino>
```

### Paso 2 — Crear `mcp.env` con los tokens y conexiones

```powershell
Copy-Item mcp.env.example mcp.env
notepad mcp.env   # llenar con los valores reales
```

```env
# PostgreSQL — una variable por proyecto (convención: NOMBRE_DEV)
PROYECTO_DEV=postgresql://usuario:password@host:5432/nombre_db

# SQL Server — una variable por proyecto (convención: NOMBRE_SS)
PROYECTO_SS=Server=host,1433;Database=nombre;User Id=usuario;Password=pass;TrustServerCertificate=True

# GitHub
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```

Ver `mcp.env.example` para la lista completa de variables disponibles.

### Paso 3 — Correr el instalador

```powershell
.\setup.ps1
```

Opciones sin wizard interactivo:

```powershell
.\setup.ps1 -Tool claude        # solo Claude Code
.\setup.ps1 -Tool codex         # solo Codex
.\setup.ps1 -Tool both          # Claude Code + Codex
.\setup.ps1 -ProjectsRoot "D:\MisProyectos"  # path de proyectos diferente
.\setup.ps1 -UseEngram yes      # forzar Engram sin preguntar
```

### Paso 4 — Reiniciar la herramienta

Cerrar y reabrir Claude Code y/o Codex. Skills, MCPs y memoria quedan disponibles automáticamente.

---

## Qué instala el script

### Claude Code (`~/.claude/`)

| Qué | Dónde queda |
|---|---|
| Skills | `~/.claude/commands/*.md` |
| Reglas globales | `~/.claude/CLAUDE.md` |
| Registry de proyectos | `~/.claude/projects-registry.md` |
| Memoria Engram | `~/.claude/projects/.../memory/*.md` |
| MCPs (DBs, GitHub, memory) | `~/.claude/settings.json` → `mcpServers` |
| Hook commits → Engram | `~/.claude/hooks/on-git-commit.ps1` |
| Hook Stop → Engram | `~/.claude/settings.json` → `hooks.Stop` (agent) |
| Auto-update en SessionStart | `~/.claude/settings.json` → `hooks.SessionStart` |

### Codex (`~/.codex/`)

| Qué | Dónde queda |
|---|---|
| Skills | `~/.codex/skills/<nombre>/SKILL.md` |
| Reglas globales | `~/.codex/engram-instructions.md` |
| Registry de proyectos | `~/.codex/projects-registry.md` |
| Memoria Engram | `~/.codex/memory/*.md` |
| MCPs (DBs, GitHub, filesystem) | `~/.codex/config.toml` → `[mcp_servers.*]` |
| Permisos de escritura | `~/.codex/config.toml` → `[approvals]` |
| Hook commits → Engram | `~/.codex/config.toml` → `[[PostToolUse]]` |

### Compartido

- Los tokens del `mcp.env` se cargan como **variables de entorno del sistema** — ambas herramientas los leen automáticamente
- Si **engram** está instalado, ambas herramientas comparten la misma base de conocimiento
- `auto-update.ps1` sincroniza el repo al iniciar sesión y al cerrarla

---

## Sistema de memoria (Engram)

La memoria funciona en dos niveles complementarios:

| Nivel | Qué es | Cuándo se usa |
|---|---|---|
| **Archivos** (`memory/*.md`) | Contexto persistente legible — proyectos, clientes, decisiones | Siempre disponible, sin depender de MCPs |
| **MCP memory** (`@modelcontextprotocol/server-memory`) | Knowledge graph estructurado | Cuando el MCP está activo |

### Qué se guarda automáticamente

- **Al hacer `git commit`** → `on-git-commit.ps1` agrega una entrada a `memory/changes-log.md`
- **Al cerrar sesión (`/exit`)** → agent Engram lee el transcript, clasifica la sesión (DECISION/BUG/CONFIG/GENERAL), detecta el proyecto por las rutas tocadas, y agrega entradas al `changes-log.md`

---

## MCPs configurados

| MCP | Para qué sirve | Claude Code | Codex |
|---|---|---|---|
| **github** | Buscar código en repos, PRs, issues | ✅ | ✅ |
| **memory** | Knowledge graph Engram | ✅ | — |
| **pg-\*** | PostgreSQL — un MCP por proyecto (auto-detectado desde `mcp.env`) | ✅ | ✅ |
| **ss-\*** | SQL Server — un MCP por proyecto (auto-detectado desde `mcp.env`) | ✅ | ✅ |

> Los MCPs cloud (Jira, Slack, Microsoft 365, Figma) van por claude.ai — no requieren configuración aquí.

---

## Skills disponibles

Se activan **automáticamente por contexto** según lo configurado en `CLAUDE.md` — no siempre hace falta escribir el comando.

| Skill | Para qué |
|---|---|
| `/proyecto` | Navegar entre proyectos y workspaces con git sync |
| `/scan` | Ver qué cambió hoy, qué hizo [autor], repos pendientes |
| `/commit` | Generar commits descriptivos en español |
| `/pr` | Crear Pull Requests descriptivos |
| `/jira` | Crear epics, historias y tareas en Jira |
| `/notify` | Notificar cambios por Slack |
| `/replicate` | Copiar patrones de un repo a otro |
| `/angular` | Componentes, servicios, guards Angular |
| `/material` | Tablas, dialogs, formularios Angular Material |
| `/tailwind` | Layouts, componentes, temas Tailwind CSS |
| `/nestjs` | Módulos, controllers, DTOs, guards NestJS |
| `/dotnet` | Endpoints, DTOs, migrations .NET |
| `/nextjs` | Páginas, componentes, rutas Next.js |
| `/efcore` | DbContext, migrations, queries EF Core |
| `/typeorm` | Entidades, repos, migrations TypeORM |
| `/postgres` | Queries, índices, migrations PostgreSQL |
| `/sqlserver` | T-SQL, stored procedures, migrations SQL Server |
| `/zustand` | Stores con persist, devtools, slices |
| `/jwt` | Auth JWT y API Key en NestJS y .NET |
| `/aws` | Secrets Manager, S3, SES, DynamoDB |
| `/firebase` | Push notifications FCM, Firebase Admin |
| `/azure` | MSAL Angular, Azure AD, Azure Pipelines |
| `/supabase` | Storage, queries, realtime Supabase |
| `/swagger` | Documentación OpenAPI |
| `/testing` | Unit tests, e2e, mocks por framework |
| `/linting` | ESLint, Prettier, TSLint |
| `/docs` | PDFs con QuestPDF, Excel con ClosedXML/ExcelJS |

---

## Agregar una base de datos nueva

**Paso 1** — Agregar la variable en `mcp.env`:
```env
PROYECTO_DEV=postgresql://usuario:password@host:5432/nombre_db
```

**Paso 2** — Correr `.\setup.ps1` de nuevo. El MCP se agrega automáticamente.

---

## Actualizar en otro dispositivo

```powershell
cd <ruta-del-repo>
git pull
.\setup.ps1
# Reiniciar Claude Code y/o Codex
```

## Estructura de aliases de proyectos

| Prefijo | Cliente |
|---|---|
| `yalo *` | YALO |
| `bodega *` | La Bodega |
| `corinsa *` / `cpa *` | CORINSA |
| `ult *` | Ultimate Labs |
| `emsula *` / `doctor *` | EMSULA |
