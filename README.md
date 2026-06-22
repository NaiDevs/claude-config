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
| **filesystem** | Acceso a archivos del proyecto | ✅ | ✅ |
| **playwright** | Automatización de browser y pruebas UI | — (plugin) | ✅ |
| **pg-\*** | PostgreSQL — auto-detectado desde `mcp.env` | ✅ | ✅ |
| **ss-\*** | SQL Server — auto-detectado desde `mcp.env` | ✅ | ✅ |
| **redis-\*** | Redis — auto-detectado desde `mcp.env` | ✅ | ✅ |

> Los MCPs cloud (Jira, Slack, Microsoft 365, Figma) van por claude.ai — no requieren configuración aquí.

---

## Conectores Claude cloud vs MCPs locales

Hay dos tipos de integración: **conectores cloud** (disponibles en claude.ai sin instalar nada) y **MCPs locales** (se instalan en este repo y sirven para Claude Code y Codex).

| Servicio | Claude cloud | MCP local | Motivo |
|---|---|---|---|
| **Atlassian (Jira/Confluence)** | ✅ | ❌ no necesario | Solo lectura/escritura desde la web — no hay acceso a instancias locales |
| **Figma** | ✅ | ❌ no necesario | El conector cloud tiene acceso completo a la API |
| **Microsoft 365** | ✅ | ❌ no necesario | Outlook, Teams y SharePoint cloud-only |
| **Microsoft Learn** | ✅ | ❌ no necesario | Documentación pública, sin estado local |
| **Slack** | ✅ | ❌ no necesario | API Slack opera sobre canales remotos |
| **GitHub** | ✅ cloud | ⚙️ opcional local | El conector cloud cubre PRs y búsqueda. El MCP local es útil si Codex necesita git local desde CLI |
| **Google Drive** | ✅ | ❌ no necesario | Archivos en la nube, no locales |
| **Notion** | ✅ | ❌ no necesario | Base de conocimiento cloud |
| **Supabase** | ✅ cloud | ⚙️ opcional local | Cloud cubre storage y queries remotos. Local útil si tienes instancia propia |
| **Vercel** | ✅ cloud | ⚙️ opcional local | Cloud cubre deploys. Local útil si tienes mucho CI/CD vía CLI |
| **Cloudflare** | ✅ | ❌ no necesario | Workers y DNS son cloud-only |
| **Stripe / PayPal / Brex** | ✅ | ❌ no necesario | APIs de pagos cloud, sin estado local |
| **Calendly / Intercom / Webflow / Canva / Lovable** | ✅ | ❌ no necesario | SaaS cloud, no hay instancias locales |
| **tldraw** | ✅ | ❌ no necesario | Diagramas en la nube |
| **Linear** | ✅ | ❌ no necesario | Issue tracker cloud |
| **PostgreSQL** | ❌ | ✅ obligatorio | DB local o VPN — requiere conexión directa |
| **SQL Server** | ❌ | ✅ obligatorio | DB local o VPN — requiere conexión directa |
| **Redis** | ❌ | ✅ recomendado | Cache local — requiere conexión directa |
| **Playwright** | ✅ plugin (Claude) | ✅ MCP (Codex) | Para automatización UI y tests locales |
| **filesystem** | ❌ | ✅ obligatorio | Acceso a archivos del proyecto en disco |
| **Docker** | ❌ | ⚙️ opcional | Útil para inspeccionar contenedores locales |
| **Firebase Admin** | ❌ | ⚙️ opcional | Si tienes proyectos FCM activos |
| **AWS** | ❌ | ⚙️ opcional | Si usas Secrets Manager, S3, SES directamente |
| **Azure** | ❌ | ⚙️ opcional | Si tienes servicios Azure que Codex necesita consultar |
| **Engram/memory** | ❌ | ✅ obligatorio | Memoria persistente entre sesiones |

---

## MCPs recomendados para flujo FullStack

Según el stack (NestJS + Angular + TypeScript + TypeORM + PostgreSQL + SQL Server):

```
# Obligatorios
filesystem          — acceso a archivos del proyecto
postgres (pg-*)     — TypeORM, queries, migraciones
sqlserver (ss-*)    — reportes, BI, datos legados

# Recomendados
redis (redis-*)     — caché, sesiones, queues con Bull
playwright          — pruebas E2E, automatización UI, debugging visual
github              — code review, búsqueda en repos, PRs
memory/engram       — memoria entre sesiones de trabajo

# Opcionales — configurar si los usas activamente
firebase-admin      — FCM, push notifications, Cloud Messaging
aws                 — Secrets Manager, S3, SES
azure               — Azure AD, servicios Microsoft
docker              — inspeccionar contenedores, logs de servicios
```

### Cómo agregar Redis

1. Agregar en `mcp.env`:
```env
YALO_REDIS=redis://localhost:6379
```
2. Correr `.\setup.ps1` — genera MCP `redis-yalo` automáticamente.

### Cómo agregar Playwright (Codex)

Se instala automáticamente con `.\setup.ps1`. No requiere configuración extra.

### Firebase Admin, AWS, Azure

Estos MCPs requieren credenciales específicas. Agregar las variables en `mcp.env` (ver `mcp.env.example`) y luego extender `setup.ps1` manualmente para configurarlos — no se auto-detectan por seguridad.

---

## Qué NO duplicar localmente si ya está en Claude cloud

Si ya tenés estos conectores en claude.ai, **no tiene sentido instalarlos como MCP local** salvo que Codex o un script CLI realmente necesite operar contra esos servicios sin la interfaz web:

- **Atlassian** (Jira, Confluence) — el conector cloud ya tiene acceso completo
- **Figma** — el plugin de Figma en Claude Code es superior al MCP local
- **Microsoft 365** — Outlook, Teams, SharePoint son cloud-only
- **Microsoft Learn** — documentación pública, el conector cloud está optimizado
- **Slack** — los mensajes y canales están en la nube
- **Google Drive** — archivos en Drive no son archivos locales
- **Notion** — base de conocimiento cloud
- **tldraw** — diagramas en la nube
- **Canva, Webflow, Lovable** — editores cloud sin estado local
- **Intercom, Calendly** — SaaS cloud puro
- **Brex, Stripe, PayPal** — APIs de pagos, nunca con acceso directo local
- **Cloudflare** — Workers y DNS son 100% cloud
- **Linear** — issue tracker cloud (usa Jira igual)

> **Regla práctica**: si la herramienta no tiene datos locales ni necesita acceso desde CLI fuera del browser, el conector cloud es suficiente. Los MCPs locales son para bases de datos, archivos, herramientas de desarrollo y servicios con instancias locales.

---

## Skills disponibles

Se activan **automáticamente por contexto** según `CLAUDE.md` (Claude Code) y `AGENTS.md` (Codex). No siempre hace falta escribir el slash command.

> **Claude Code** carga skills desde `~/.claude/commands/*.md` — las activa por palabras clave en la conversación.
> **Codex** carga skills desde `~/.codex/skills/<name>/SKILL.md` — las activa por el campo `description` del frontmatter. Por eso las descriptions son largas y keyword-heavy en inglés.

### Flujo de trabajo
| Skill | Para qué |
|---|---|
| `/proyecto` | Navegar entre proyectos y workspaces con git sync |
| `/scan` | Ver qué cambió hoy, qué hizo [autor], repos pendientes |
| `/commit` | Generar commits descriptivos en español |
| `/pr` | Crear Pull Requests descriptivos |
| `/jira` | Crear epics, historias y tareas en Jira |
| `/notify` | Notificar cambios por Slack |
| `/replicate` | Copiar patrones de un repo a otro |

### Frameworks y lenguajes
| Skill | Para qué |
|---|---|
| `/nestjs` | Módulos, controllers, DTOs, guards, decoradores NestJS |
| `/angular` | Componentes standalone, servicios, guards, formularios Angular 15+ |
| `/material` | Tablas, dialogs, formularios, paginadores Angular Material |
| `/tailwind` | Layouts, componentes, temas Tailwind CSS |
| `/dotnet` | Endpoints, DTOs, migrations, Swagger .NET |
| `/nextjs` | Páginas, componentes, rutas Next.js |

### Bases de datos y ORM
| Skill | Para qué |
|---|---|
| `/typeorm` | Entidades, repos, relations, migrations TypeORM 0.3.x |
| `/efcore` | DbContext, migrations, queries EF Core |
| `/postgres` | Queries, índices, JSONB, migrations PostgreSQL |
| `/sqlserver` | T-SQL, stored procedures, migrations SQL Server |
| `/migration` | Workflow completo para migrations: generate, review, run, rollback |

### Auth y seguridad
| Skill | Para qué |
|---|---|
| `/jwt` | Auth JWT y API Key en NestJS y .NET |
| `/permissions` | Sistema dinámico de permisos por módulo/acción, guards, directives Angular |
| `/security` | OWASP: SQL injection, IDOR, secrets, CORS — revisión y fix |

### Cloud y servicios externos
| Skill | Para qué |
|---|---|
| `/aws` | Secrets Manager, S3, SES, DynamoDB |
| `/firebase` | Firebase Admin genérico |
| `/firebase-fcm` | Push notifications FCM: FcmService, device tokens, topics |
| `/azure` | MSAL Angular, Azure AD, Azure Pipelines |
| `/supabase` | Storage, queries, realtime Supabase |

### Calidad y documentación
| Skill | Para qué |
|---|---|
| `/swagger` | Documentación OpenAPI completa con @ApiTags, @ApiOperation, @ApiResponse |
| `/api-contract` | Contratos API, request/response DTOs, compatibilidad frontend-backend |
| `/testing` | Unit tests, e2e, mocks por framework |
| `/linting` | ESLint, Prettier, TSLint |
| `/docs` | PDFs con QuestPDF, Excel con ClosedXML/ExcelJS |
| `/pdfkit` | Generación de PDFs con PDFKit: tablas, headers, footers, saltos de página |
| `/zustand` | Stores con persist, devtools, slices |

### Arquitectura y mantenimiento
| Skill | Para qué |
|---|---|
| `/architect` | Diseño de features, estructura de módulos, decisiones técnicas |
| `/refactor` | Refactoring controlado: extraer servicios, mejorar nombres, tipos |
| `/performance` | N+1, índices faltantes, caching Redis, lazy loading Angular |
| `/debug` | Bugs, errores, excepciones, endpoints que fallan |
| `/db-audit` | Queries lentas, duplicados, EXPLAIN ANALYZE, datos incorrectos |
| `/review` | Code review: arquitectura, correctness, seguridad, calidad |
| `/release` | Workflow de deploy: CHANGELOG, orden de deploy, post-deploy |
| `/hotfix` | Fix urgente: evaluate → reproduce → minimal fix → deploy |
| `/doctor` | Diagnóstico de proyecto: dependencias, .env, DB, build |

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
