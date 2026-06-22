# agent-ai-config

Configuración personal para **Claude Code** y/o **Codex** — skills, reglas globales, MCPs, memoria persistente Engram, hooks automáticos e instalación reproducible en cualquier dispositivo.

Un solo repo, un solo `setup.ps1`, compatible con ambas herramientas.

---

## Quick Start

```powershell
# 1. Clonar
git clone https://github.com/NaiDevs/agent-ai-config.git <ruta-destino>
cd <ruta-destino>

# 2. Configurar secrets
Copy-Item mcp.env.example mcp.env
notepad mcp.env

# 3. Instalar
.\setup.ps1

# 4. Validar
.\doctor.ps1
```

Reiniciar Claude Code y/o Codex después del setup.

---

## Requisitos

| Requisito | Versión mínima | Para qué |
|---|---|---|
| Git | 2.x | Obligatorio |
| Node.js + npm | 18+ | MCPs via `npx` |
| PowerShell | 5.1 (Windows) / 7+ (Mac/Linux) | Scripts de setup y hooks |
| Claude Code | cualquier | Si vas a usar Claude Code |
| Codex | cualquier | Si vas a usar Codex |
| engram | opcional | Knowledge graph MCP adicional |

---

## Estructura del repo

```
agent-ai-config/
├── CLAUDE.md                  # Reglas globales + auto-activación de skills
├── projects-registry.md       # Aliases, paths, Jira keys y workspaces
├── mcp.env.example            # Plantilla de tokens y connection strings
├── expressions.md             # Expresiones hondureñas para personalidad
│
├── commands/                  # Skills de Claude Code / Codex
│   ├── angular.md
│   ├── commit.md
│   └── ...                    # 27 skills en total
│
├── memory/                    # Memoria persistente Engram
│   ├── MEMORY.md              # Índice
│   ├── changes-log.md         # Log automático de commits y sesiones
│   ├── projects-*.md          # Contexto por cliente
│   └── ...
│
├── hooks/
│   └── on-git-commit.ps1      # Hook PostToolUse — commits → Engram
│
├── setup.ps1                  # Instalador principal
├── auto-update.ps1            # Sincronización automática al iniciar sesión
├── sync.ps1                   # Copia memoria de vuelta al repo
├── doctor.ps1                 # Valida la instalación
└── uninstall.ps1              # Quita archivos instalados por este repo
```

---

## Instalación en nuevo dispositivo

### Paso 1 — Clonar el repo

```powershell
git clone https://github.com/NaiDevs/agent-ai-config.git <ruta-destino>
cd <ruta-destino>
```

### Paso 2 — Crear `mcp.env`

```powershell
Copy-Item mcp.env.example mcp.env
notepad mcp.env   # llenar con los valores reales
```

### Paso 3 — Correr el instalador

```powershell
.\setup.ps1
```

Opciones disponibles:

```powershell
.\setup.ps1 -Tool claude              # solo Claude Code
.\setup.ps1 -Tool codex               # solo Codex
.\setup.ps1 -Tool both                # ambos (default)
.\setup.ps1 -ProjectsRoot "D:\Work"   # carpeta de proyectos personalizada
.\setup.ps1 -UseEngram yes            # forzar Engram sin preguntar
.\setup.ps1 -SkipRegistryOverwrite    # conservar tu projects-registry.md local
```

### Paso 4 — Validar

```powershell
.\doctor.ps1
```

### Paso 5 — Reiniciar

Cerrar y reabrir Claude Code y/o Codex.

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

- Los tokens de `mcp.env` se cargan como variables de entorno del sistema — ambas herramientas los leen automáticamente
- Si **engram** está instalado, ambas herramientas comparten la misma base de conocimiento
- `auto-update.ps1` sincroniza el repo en cada inicio de sesión

---

## Seguridad

### Archivos protegidos por `.gitignore`

- `mcp.env` — tokens y connection strings reales. **Nunca subir al repo.**
- `*.local.json` — configuración específica de la máquina
- `.last-update.log` — estado interno de sincronización
- `tmp/` — archivos temporales

### Principio de mínimo privilegio

- El **GitHub token** solo necesita: `repo`, `read:org`, `read:user`
- Los tokens de DBs deben ser usuarios de solo lectura si es posible
- Nunca usar credenciales de producción en `mcp.env`

### Qué NO guardar en memoria Engram

- Passwords ni connection strings reales
- API keys completas
- Datos de clientes (PII, financieros, médicos)
- Secretos de producción

La memoria Engram es para contexto técnico (qué proyecto, qué stack, qué decisión), no para secretos.

---

## Validación post-instalación

```powershell
.\doctor.ps1              # valida todo
.\doctor.ps1 -Tool claude # solo Claude Code
.\doctor.ps1 -Tool codex  # solo Codex
```

El script revisa: git, Node.js, Claude Code, Codex, engram, `mcp.env`, variables de entorno, archivos instalados, JSON/TOML válidos.

---

## Sistema de memoria (Engram)

La memoria funciona en dos niveles complementarios:

| Nivel | Qué es | Disponibilidad |
|---|---|---|
| **Archivos** (`memory/*.md`) | Contexto legible — proyectos, clientes, decisiones | Siempre, sin MCPs |
| **MCP memory** | Knowledge graph estructurado | Solo cuando el MCP está activo |

### Qué se guarda automáticamente

- **Al hacer `git commit`** → `on-git-commit.ps1` agrega entrada a `memory/changes-log.md`
- **Al cerrar sesión (`/exit`)** → agente Engram analiza el transcript, clasifica (DECISION/BUG/CONFIG/GENERAL), detecta el proyecto por rutas tocadas, y actualiza `changes-log.md`

### Qué NO se guarda

Ver sección **Seguridad** — nunca guardar secretos, PII ni credenciales de producción.

### Si engram no está instalado

El sistema funciona igual — solo usando los archivos `memory/*.md`. El MCP de knowledge graph no estará disponible, pero el historial de commits y sesiones sí.

### Revisar el log

```powershell
# Ver cambios recientes
Get-Content ~/.claude/projects/.../memory/changes-log.md | Select-Object -Last 20
```

---

## Convención de variables MCP

Las variables en `mcp.env` siguen una convención que `setup.ps1` traduce automáticamente a MCPs:

| Variable | MCP generado | Tipo |
|---|---|---|
| `PROYECTO_DEV` | `pg-proyecto` | PostgreSQL |
| `PROYECTO_SS` | `ss-proyecto` | SQL Server |

**Formato PostgreSQL:**
```env
PROYECTO_DEV=postgresql://usuario:password@host:5432/nombre_db
```

**Formato SQL Server:**
```env
PROYECTO_SS=Server=host,1433;Database=nombre;User Id=usuario;Password=pass;TrustServerCertificate=True
```

Los MCPs quedan disponibles en Claude Code (`settings.json → mcpServers`) y Codex (`config.toml → [mcp_servers.*]`).

---

## MCPs configurados

| MCP | Para qué sirve | Claude Code | Codex |
|---|---|---|---|
| **github** | Buscar código en repos, PRs, issues | ✅ | ✅ |
| **memory** | Knowledge graph Engram | ✅ | — |
| **pg-\*** | PostgreSQL — auto-detectado desde `mcp.env` | ✅ | ✅ |
| **ss-\*** | SQL Server — auto-detectado desde `mcp.env` | ✅ | ✅ |

> Los MCPs cloud (Jira, Slack, Microsoft 365, Figma) van por claude.ai — no requieren configuración aquí.

---

## Skills disponibles

Se activan **automáticamente por contexto** según `CLAUDE.md`. No siempre hace falta escribir el comando.

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

### Cómo agregar una nueva skill

1. Crear `commands/nombre-skill.md` con esta estructura mínima:

```markdown
---
name: nombre-skill
description: Para qué sirve esta skill (una línea)
---

# /nombre-skill

## Cuándo usar
...

## Instrucciones
...

## Reglas
...

## Ejemplos
...
```

2. Correr `.\setup.ps1` — se despliega automáticamente a `~/.claude/commands/` y `~/.codex/skills/`.

---

## Formato de `projects-registry.md`

Cada proyecto sigue esta estructura:

```markdown
## alias largo
- path: C:\ruta\al\proyecto
- cliente: NOMBRE_CLIENTE
- jira: JIRA_KEY
- workspace: nombre-workspace
- stack: NestJS / Angular / .NET / etc
- db: NOMBRE_DEV  (variable en mcp.env, opcional)
```

Los workspaces agrupan proyectos que se abren juntos. Se definen al final del archivo:

```markdown
## Workspaces

| Workspace | Proyectos |
|---|---|
| nombre-ws | alias1, alias2, alias3 |
```

---

## Agregar una base de datos nueva

**Paso 1** — Agregar la variable en `mcp.env`:
```env
NUEVO_PROYECTO_DEV=postgresql://usuario:password@host:5432/nombre_db
```

**Paso 2** — Correr `.\setup.ps1` de nuevo. El MCP se agrega automáticamente.

---

## Limitaciones conocidas: Claude Code vs Codex

| Feature | Claude Code | Codex |
|---|---|---|
| MCP memory (knowledge graph) | ✅ | ❌ No soporta |
| Hook Stop (agent Engram) | ✅ | ❌ Solo command hooks |
| Hooks SessionStart | ✅ | ❌ |
| Skills en `commands/` | ✅ | Via `skills/<nombre>/SKILL.md` |
| Permissions granulares | `permissions.allow[]` | `[approvals]` |
| Instrucciones globales | `CLAUDE.md` | `engram-instructions.md` |

---

## Actualizar en otro dispositivo

```powershell
cd <ruta-del-repo>
git pull
.\setup.ps1
# Reiniciar Claude Code y/o Codex
```

## Desinstalar

```powershell
.\uninstall.ps1               # quita skills, commands y hooks
.\uninstall.ps1 -IncludeMemory  # también borra memoria (pide confirmación)
```

---

## Estructura de aliases de proyectos

| Prefijo | Cliente |
|---|---|
| `yalo *` | YALO |
| `bodega *` | La Bodega |
| `corinsa *` / `cpa *` | CORINSA |
| `ult *` | Ultimate Labs |
| `emsula *` / `doctor *` | EMSULA |

---

## Troubleshooting

**El hook de commits no registra nada**
→ Verificar que `~/.claude/hooks/on-git-commit.ps1` existe. Correr `.\doctor.ps1`.
→ El hook solo detecta `git commit` ejecutados directamente, no via GUI.

**`setup.ps1` falla en el paso de MCPs**
→ Verificar que Node.js y npm están instalados: `node --version && npm --version`.
→ Si hay error de permisos de npm, correr PowerShell como administrador.

**Los skills no aparecen en Claude Code**
→ Reiniciar Claude Code después del setup.
→ Verificar que `~/.claude/commands/` tiene archivos `.md`.

**Codex no encuentra los MCPs de base de datos**
→ Las variables de entorno se configuran al nivel de usuario. Después de correr `setup.ps1`, reiniciar la terminal y Codex.

**`auto-update.ps1` sobreescribe cambios locales**
→ Tiene throttle de 30 min — no corre en cada sesión.
→ Si modificaste `projects-registry.md` localmente, commitearlo al repo primero.

---

## Roadmap

- [ ] Soporte para hook Stop en Codex (pendiente de feature en Codex)
- [ ] MCP memory en Codex
- [ ] `doctor.ps1` con fix automático para errores comunes
- [ ] Tests con Pester para validar setup
- [ ] Soporte para múltiples vaults de configuración (trabajo vs personal)
