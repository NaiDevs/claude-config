# claude-config

Configuración personal para **Claude Code** y/o **Codex** — proyectos, aliases, workspaces, skills, MCPs y memoria persistente.

Un solo repo, un solo `setup.ps1`, compatible con ambas herramientas.

---

## Contenido del repo

| Archivo/Carpeta | Para qué sirve |
|---|---|
| `CLAUDE.md` | Reglas siempre activas + auto-activación de skills |
| `projects-registry.md` | Aliases de proyectos, Jira keys y workspaces |
| `commands/*.md` | 26 skills (`/angular`, `/nestjs`, `/dotnet`, `/swagger`, etc.) |
| `memory/*.md` | Memoria persistente por cliente (6 clientes, 58 proyectos) |
| `mcp-config.json` | Referencia de MCPs locales configurados |
| `mcp.env.example` | Plantilla de tokens y conexiones (copiar a `mcp.env`) |
| `setup.ps1` | Instalador — detecta Claude Code y/o Codex automáticamente |
| `mcp-secrets-guide.md` | Dónde obtener cada token |

---

## Instalación en nuevo dispositivo

### Paso 1 — Clonar el repo

```powershell
git clone https://github.com/NaiDevs/claude-config.git "$env:USERPROFILE\.claude\claude-config"
cd "$env:USERPROFILE\.claude\claude-config"
```

### Paso 2 — Crear `mcp.env` con los tokens y conexiones

```powershell
Copy-Item mcp.env.example mcp.env
notepad mcp.env   # llenar con los valores reales
```

Estructura del archivo (ver detalle más abajo):
```env
LABODEGA_DEV=postgresql://postgres:password@localhost:5432/labodega_dev
YALO_DEV=postgresql://postgres:password@localhost:5432/yalo_dev
CORINSA_DEV=postgresql://postgres:password@localhost:5432/corinsa_dev
ULTIMATELABS_DEV=postgresql://postgres:password@localhost:5432/ultimatelabs_dev
EMSULA_DEV=postgresql://postgres:password@localhost:5432/emsula_dev
CORINSA_SS=Server=localhost,1433;Database=corinsa;User Id=sa;Password=password;TrustServerCertificate=True
EMSULA_SS=Server=localhost,1433;Database=emsula;User Id=sa;Password=password;TrustServerCertificate=True
YALO_SS=Server=localhost,1433;Database=yalo;User Id=sa;Password=password;TrustServerCertificate=True
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```

### Paso 3 — Correr el instalador

El script detecta automáticamente qué herramientas tienes instaladas:

```powershell
.\setup.ps1
```

O forzar una herramienta específica:

```powershell
.\setup.ps1 -Tool claude   # solo Claude Code
.\setup.ps1 -Tool codex    # solo Codex
.\setup.ps1 -Tool both     # Claude Code + Codex
```

Con un path de proyectos diferente:
```powershell
.\setup.ps1 -ProjectsRoot "D:\MisProyectos"
```

### Paso 4 — Reiniciar la herramienta

Cerrar y reabrir Claude Code y/o Codex. Los skills, MCPs y memoria quedan disponibles automáticamente.

---

## Qué instala el script por herramienta

### Claude Code (`~/.claude/`)

| Qué | Dónde queda |
|---|---|
| 26 skills | `~/.claude/commands/*.md` |
| Reglas globales | `~/.claude/CLAUDE.md` |
| Registry de proyectos | `~/.claude/projects-registry.md` |
| Memoria (6 clientes) | `~/.claude/projects/.../memory/*.md` |
| MCPs (DBs, GitHub, filesystem) | `~/.claude/settings.json` → `mcpServers` |
| Permiso de escritura | `~/.claude/settings.json` → `permissions.allow` |

### Codex (`~/.codex/`)

| Qué | Dónde queda |
|---|---|
| 26 skills | `~/.codex/skills/<nombre>/SKILL.md` |
| Reglas globales | Agrega a `~/.codex/engram-instructions.md` (sin sobreescribir) |
| MCPs (DBs, GitHub, filesystem) | `~/.codex/config.toml` → `[mcp_servers.*]` |

### Compartido (ambas herramientas)

- Los tokens del `mcp.env` se cargan como **variables de entorno del sistema** — ambas herramientas los leen automáticamente
- Si **engram** está instalado, ambas comparten la misma memoria

---

## Tokens y conexiones de bases de datos

El archivo `mcp.env` **nunca se sube al repo** (está en `.gitignore`).

### GitHub Token — `GITHUB_PERSONAL_ACCESS_TOKEN`

1. Ir a **github.com → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Clic en **"Generate new token (classic)"**
3. Permisos mínimos: `repo`, `read:org`, `read:user`
4. Copiar el token `ghp_...`

### PostgreSQL — una variable por proyecto

```
Formato: postgresql://usuario:password@host:puerto/nombre_db
```

```env
LABODEGA_DEV=postgresql://postgres:password@localhost:5432/labodega_dev
YALO_DEV=postgresql://postgres:password@localhost:5432/yalo_dev
CORINSA_DEV=postgresql://postgres:password@localhost:5432/corinsa_dev
ULTIMATELABS_DEV=postgresql://postgres:password@localhost:5432/ultimatelabs_dev
EMSULA_DEV=postgresql://postgres:password@localhost:5432/emsula_dev
```

### SQL Server — una variable por proyecto

```
Formato: Server=host,puerto;Database=nombre;User Id=usuario;Password=pass;TrustServerCertificate=True
```

```env
CORINSA_SS=Server=localhost,1433;Database=corinsa;User Id=sa;Password=pass;TrustServerCertificate=True
EMSULA_SS=Server=localhost,1433;Database=emsula;User Id=sa;Password=pass;TrustServerCertificate=True
YALO_SS=Server=localhost,1433;Database=yalo;User Id=sa;Password=pass;TrustServerCertificate=True
```

---

## Agregar una base de datos nueva

**Paso 1** — Agregar la variable en `mcp.env`:
```env
NUEVO_PROYECTO_DEV=postgresql://postgres:password@localhost:5432/nuevo_db
```

**Paso 2** — Agregar en `mcp-config.json` (referencia del repo) y correr `.\setup.ps1` de nuevo.

O agregar manualmente:

- **Claude Code** — en `~/.claude/settings.json`, sección `mcpServers`:
```json
"pg-nuevo": {
  "command": "powershell",
  "args": ["-Command", "npx -y mcp-server-postgres $env:NUEVO_PROYECTO_DEV"]
}
```

- **Codex** — en `~/.codex/config.toml`:
```toml
[mcp_servers.pg-nuevo]
command = "powershell"
args = ["-Command", "npx -y mcp-server-postgres $env:NUEVO_PROYECTO_DEV"]
```

Reiniciar la herramienta después de cada cambio.

---

## MCPs locales configurados

| MCP | Para qué sirve | Claude Code | Codex |
|---|---|---|---|
| **github** | Buscar código en repos, PRs, issues | ✅ | ✅ |
| **filesystem** | Acceso a todos los proyectos sin cd | ✅ | ✅ |
| **memory** | Knowledge graph complementario | ✅ | ✅ |
| **pg-labodega** | PostgreSQL — La Bodega | ✅ | ✅ |
| **pg-yalo** | PostgreSQL — YALO | ✅ | ✅ |
| **pg-corinsa** | PostgreSQL — CORINSA | ✅ | ✅ |
| **pg-ultimatelabs** | PostgreSQL — Ultimate Labs | ✅ | ✅ |
| **pg-emsula** | PostgreSQL — EMSULA | ✅ | ✅ |
| **ss-corinsa** | SQL Server — CORINSA legacy | ✅ | ✅ |
| **ss-emsula** | SQL Server — EMSULA Doctor legacy | ✅ | ✅ |
| **ss-yalo** | SQL Server — YALO legacy | ✅ | ✅ |

> Los MCPs cloud (Jira, Slack, Microsoft 365, Figma) van por cuenta de claude.ai — no requieren configuración aquí.

---

## Skills disponibles (`/comando`)

Los skills se activan **automáticamente por contexto** — no siempre es necesario escribir el comando. Claude/Codex detecta la tecnología y activa el skill correspondiente.

| Skill | Para qué |
|---|---|
| `/proyecto` | Navegar entre proyectos y workspaces con git sync |
| `/scan` | Ver qué cambió hoy, qué hizo [autor], repos pendientes |
| `/commit` | Generar commits descriptivos en español |
| `/pr` | Crear Pull Requests descriptivos |
| `/jira` | Crear epics, historias y tareas en Jira |
| `/notify` | Notificar cambios a compañeros por Slack |
| `/angular` | Componentes, servicios, guards Angular |
| `/material` | Tablas, dialogs, formularios Angular Material |
| `/tailwind` | Layouts, componentes, temas Tailwind CSS |
| `/nestjs` | Módulos, controllers, DTOs, guards NestJS |
| `/dotnet` | Endpoints, DTOs, migrations .NET |
| `/nextjs` | Páginas, componentes, stores Next.js |
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
| `/swagger` | Documentación OpenAPI estándar YaloVendo |
| `/testing` | Unit tests, e2e, mocks por framework |
| `/linting` | ESLint, Prettier, TSLint |
| `/docs` | PDFs con QuestPDF, Excel con ClosedXML/ExcelJS |

---

## Actualizar en otro dispositivo

```powershell
git -C "$env:USERPROFILE\.claude\claude-config" pull
cd "$env:USERPROFILE\.claude\claude-config"
.\setup.ps1
# Reiniciar Claude Code y/o Codex
```

## Editar aliases o workspaces

```powershell
# Editar la fuente de verdad
code "$env:USERPROFILE\.claude\projects-registry.md"

# Sincronizar al repo
git -C "$env:USERPROFILE\.claude\claude-config" add projects-registry.md
git -C "$env:USERPROFILE\.claude\claude-config" commit -m "update aliases"
git -C "$env:USERPROFILE\.claude\claude-config" push
```

## Estructura de aliases de proyectos

| Prefijo | Cliente |
|---|---|
| `yalo *` | YALO |
| `bodega *` | La Bodega |
| `bi *` / `cpa *` | CORINSA |
| `ult *` | Ultimate Labs |
| `doctor *` | EMSULA Doctor |
| `nai *` | NAI (personal) |
