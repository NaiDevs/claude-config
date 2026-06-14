---
description: Navega entre proyectos y workspaces por alias, muestra git status y sincroniza con remotos
---

# proyecto

Lee `~/.claude/projects-registry.md` para resolver aliases de proyectos y workspaces. Gestiona navegación entre proyectos y sincronización con repositorios remotos usando subagentes Haiku para operaciones git.

## Modelo a usar

- **Haiku**: todas las operaciones git (fetch, status, log) — en subagentes
- **Sonnet**: ensamblado de respuestas, análisis de código
- **Opus**: nunca sin consultar al usuario primero

## Uso

```
/proyecto [alias]          → Activa un proyecto específico
/proyecto ws [workspace]   → Activa un workspace (múltiples repos)
/proyecto list             → Lista todos los proyectos por cliente
/proyecto list [cliente]   → Solo los proyectos de ese cliente
/proyecto ws list          → Lista todos los workspaces definidos
/proyecto sync [alias]     → git pull directo sin confirmar
/proyecto github [alias]   → Muestra commits remotos pendientes
```

## Instrucciones de comportamiento

### Al invocar `/proyecto [alias]`

1. Leer `~/.claude/projects-registry.md` (case-insensitive)
2. Construir el path completo: `<base_path_del_cliente>\<carpeta>`
3. Ejecutar `cd "<path>"`
4. Lanzar un **subagente Haiku** que recibe solo el path y devuelve:
   - Branch actual
   - `git status --short`
   - `git log --oneline -5 --format="%h %ad %an: %s" --date=short`
   - Commits remotos pendientes: `git log HEAD..@{u} --oneline 2>/dev/null`
5. Mostrar resumen: alias, path, stack, proyectos relacionados + output del subagente
6. Si hay commits remotos: preguntar "¿Hacemos git pull?"

### Al invocar `/proyecto ws [workspace]`

1. Leer sección Workspaces de `~/.claude/projects-registry.md`
2. Resolver cada alias a su path completo
3. Lanzar un **subagente Haiku por repo** en paralelo. Cada uno devuelve:
   - Branch + último commit + cuántos commits detrás del remoto
4. Mostrar tabla de status unificado:

```
┌─ workspace: yalo bo ───────────────────────────────┐
│ yalo bo     │ ..\YALO\YaloPOSBackoffice            │
│             │ ✓ Al día  (branch: main)              │
├─────────────┼──────────────────────────────────────┤
│ yalo bo api │ ..\YALO\YaloPOSBackofficeAPI         │
│             │ ↓ 2 commits por bajar  (branch: dev)  │
│             │ Último: "fix: endpoint facturas" 3h   │
└─────────────┴──────────────────────────────────────┘
```

5. Si hay repos con commits pendientes: preguntar "¿Hacer git pull? (todos/algunos/no)"

### Con workspace activo

Cuando el usuario pregunta "¿qué cambió hoy?" o "¿hay algo sin mergear?":
- Lanzar subagentes Haiku paralelos, uno por repo del workspace
- Devolver solo lo relevante — no cargar diffs en contexto principal

### Al mencionar un alias sin invocar el skill

Si el usuario menciona un alias en conversación:
1. Reconocerlo desde la memoria
2. Informar path y stack
3. Ofrecer activar: "`/proyecto [alias]`"

### Paths base por cliente

```
YALO:          C:\Users\naide\OneDrive\Documentos\Proyectos\YALO\
LA BODEGA:     C:\Users\naide\OneDrive\Documentos\Proyectos\LA BODEGA\
CORINSA BI:    C:\Users\naide\OneDrive\Documentos\Proyectos\CORINSA BI\
CORINSA CPA:   C:\Users\naide\OneDrive\Documentos\Proyectos\CORINSA CPA\
ULTIMATE LABS: C:\Users\naide\OneDrive\Documentos\Proyectos\ULTIMATE LABS\
EMSULA DOCTOR: C:\Users\naide\OneDrive\Documentos\Proyectos\EMSULA DOCTOR\
NAI:           C:\Users\naide\OneDrive\Documentos\Proyectos\Nai\
```

### `/proyecto list` y `/proyecto list [cliente]`

Mostrar tabla compacta agrupada por cliente con alias, stack y descripción.
Filtrar por cliente si se especifica (ej. `/proyecto list yalo`, `/proyecto list bodega`).

### `/proyecto sync [alias]`

`git pull` directo sin preguntar, usando un subagente Haiku.

### `/proyecto github [alias]`

- Subagente Haiku hace `git fetch` + `git log HEAD..origin/<branch> --oneline`
- Mostrar commits remotos pendientes y rama actual vs remota
