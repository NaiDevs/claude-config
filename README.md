# claude-config

Configuración personal de Claude Code — proyectos, aliases, workspaces, skills, MCPs y memoria persistente.

## Contenido

- **`CLAUDE.md`** — Reglas siempre activas + auto-activación de skills por contexto
- **`projects-registry.md`** — Registro editable de proyectos, aliases, Jira keys y workspaces
- **`commands/`** — 26 skills personalizados (`/angular`, `/nestjs`, `/dotnet`, `/swagger`, etc.)
- **`memory/`** — Archivos de memoria por cliente (cargados automáticamente por Claude)
- **`mcp-config.json`** — Configuración de MCPs locales (GitHub, Bases de datos, Filesystem, Memory)
- **`mcp.env.example`** — Estructura de variables de entorno para MCPs (copiar a `mcp.env`)
- **`setup.ps1`** — Instalador completo para Windows

---

## Instalación en nuevo dispositivo

### 1. Clonar el repo

```powershell
git clone https://github.com/NaiDevs/claude-config.git "$env:USERPROFILE\.claude\claude-config"
cd "$env:USERPROFILE\.claude\claude-config"
```

### 2. Crear y llenar `mcp.env`

```powershell
Copy-Item mcp.env.example mcp.env
# Editar mcp.env con los valores reales (ver sección de tokens más abajo)
notepad mcp.env
```

### 3. Correr el instalador

```powershell
.\setup.ps1
```

El script instala automáticamente: commands, memoria, registry, CLAUDE.md, MCPs y carga las variables de `mcp.env` como env vars del sistema.

### 4. Reiniciar Claude Code

Los MCPs y skills quedan disponibles en la siguiente sesión.

---

## Tokens y conexiones (`mcp.env`)

El archivo `mcp.env` **nunca se sube al repo** (está en `.gitignore`). Cópialo desde `mcp.env.example` y llena los valores reales.

### GitHub Token — `GITHUB_PERSONAL_ACCESS_TOKEN`

1. Ir a **github.com → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Clic en **"Generate new token (classic)"**
3. Permisos mínimos: `repo`, `read:org`, `read:user`
4. Copiar el token `ghp_...`

### PostgreSQL — una variable por proyecto

Formato: `postgresql://usuario:password@host:puerto/nombre_db`

```env
LABODEGA_DEV=postgresql://postgres:password@localhost:5432/labodega_dev
YALO_DEV=postgresql://postgres:password@localhost:5432/yalo_dev
CORINSA_DEV=postgresql://postgres:password@localhost:5432/corinsa_dev
```

### SQL Server — una variable por proyecto

Formato: `Server=host,puerto;Database=nombre;User Id=usuario;Password=pass;TrustServerCertificate=True`

```env
CORINSA_SS=Server=localhost,1433;Database=corinsa;User Id=sa;Password=pass;TrustServerCertificate=True
EMSULA_SS=Server=localhost,1433;Database=emsula;User Id=sa;Password=pass;TrustServerCertificate=True
```

---

## Agregar una base de datos nueva

### Paso 1 — Agregar la variable en `mcp.env`

```env
# Ejemplo: nueva DB de Ultimate Labs
ULTIMATELABS_PROD=postgresql://postgres:password@prod.server.com:5432/ultimatelabs
```

### Paso 2 — Agregar el MCP en `settings.json`

Abrir `~/.claude/settings.json` y agregar una entrada en `mcpServers`:

**PostgreSQL:**
```json
"pg-ultimatelabs-prod": {
  "command": "powershell",
  "args": ["-Command", "npx -y mcp-server-postgres $env:ULTIMATELABS_PROD"]
}
```

**SQL Server:**
```json
"ss-nuevo-proyecto": {
  "command": "powershell",
  "args": ["-Command", "npx -y mssql-mcp $env:NUEVO_PROYECTO_SS"]
}
```

### Paso 3 — Recargar Claude Code

Cerrar y reabrir Claude Code. El nuevo MCP aparece automáticamente.

### Paso 4 — Actualizar el repo (para sincronizar con otros dispositivos)

```powershell
# Agregar también la variable en mcp.env.example (sin el valor real)
# Agregar la entrada en mcp-config.json

cd "$env:USERPROFILE\.claude\claude-config"
git add mcp.env.example mcp-config.json
git commit -m "feat: agrega MCP para NuevoDB"
git push
```

> En el otro dispositivo: `git pull && .\setup.ps1` — el script lee `mcp.env` y configura automáticamente.

---

## MCPs locales configurados

| MCP | Para qué sirve |
|---|---|
| **github** | Buscar código en repos, PRs, issues sin salir de Claude |
| **filesystem** | Acceso a todos los proyectos en `Proyectos/` sin hacer cd |
| **memory** | Knowledge graph complementario al sistema de memoria |
| **pg-labodega** | PostgreSQL — La Bodega (dev) |
| **pg-yalo** | PostgreSQL — YALO (dev) |
| **pg-corinsa** | PostgreSQL — CORINSA (dev) |
| **pg-ultimatelabs** | PostgreSQL — Ultimate Labs (dev) |
| **pg-emsula** | PostgreSQL — EMSULA (dev) |
| **ss-corinsa** | SQL Server — CORINSA legacy |
| **ss-emsula** | SQL Server — EMSULA Doctor legacy |
| **ss-yalo** | SQL Server — YALO legacy |

> Los MCPs cloud (Jira, Slack, Microsoft 365, Figma) se conectan por cuenta de claude.ai — no requieren configuración aquí.

---

## Skills disponibles (`/comando`)

| Skill | Para qué |
|---|---|
| `/proyecto` | Navegar entre proyectos y workspaces con git sync |
| `/scan` | Ver qué cambió hoy, qué hizo [autor], repos pendientes |
| `/commit` | Generar commits descriptivos en español |
| `/pr` | Crear Pull Requests descriptivos |
| `/jira` | Crear epics, historias y tareas en Jira |
| `/notify` | Notificar cambios a compañeros por Slack |
| `/angular` | Generar componentes, servicios, guards Angular |
| `/material` | Tablas, dialogs, formularios con Angular Material |
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

> Los skills se activan automáticamente por contexto — no siempre es necesario escribir el comando.

---

## Actualizar en otro dispositivo

```powershell
git -C "$env:USERPROFILE\.claude\claude-config" pull
.\setup.ps1
# Reiniciar Claude Code
```

## Editar aliases o workspaces

```powershell
code "$env:USERPROFILE\.claude\projects-registry.md"

git -C "$env:USERPROFILE\.claude\claude-config" add projects-registry.md
git -C "$env:USERPROFILE\.claude\claude-config" commit -m "update aliases"
git -C "$env:USERPROFILE\.claude\claude-config" push
```

## Estructura de aliases

| Prefijo | Cliente |
|---|---|
| `yalo *` | YALO |
| `bodega *` | La Bodega |
| `bi *` / `cpa *` | CORINSA |
| `ult *` | Ultimate Labs |
| `doctor *` | EMSULA Doctor |
| `nai *` | NAI (personal) |
