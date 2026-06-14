---
description: Sweeps multi-repo en paralelo — qué cambió hoy, qué hizo [autor], repos con cambios pendientes
---

# scan

Hace sweeps multi-repo eficientes usando subagentes Haiku en paralelo. Sirve para consultas del tipo "qué cambió hoy", "qué hizo [autor]" o "cuáles repos tienen cambios pendientes" — sin cargar cada repo en el contexto principal.

## Uso

```
/scan hoy              → Commits de hoy en todos los repos
/scan semana           → Commits de esta semana en todos los repos
/scan [autor]          → Commits de ese autor en todos los repos (últimos 30 días)
/scan [alias]          → Cambios recientes en un proyecto específico
/scan pendientes       → Repos con commits locales sin pushear
/scan atras            → Repos con commits remotos no bajados (requiere git fetch)
```

## Instrucciones de comportamiento

### Modelo a usar
**Siempre Haiku** para los subagentes de git. El agente principal (Sonnet) solo ensambla el reporte final.

### Paths base (leer de `~/.claude/projects-registry.md`)
```
YALO:          C:\Users\naide\OneDrive\Documentos\Proyectos\YALO\
LA BODEGA:     C:\Users\naide\OneDrive\Documentos\Proyectos\LA BODEGA\
CORINSA BI:    C:\Users\naide\OneDrive\Documentos\Proyectos\CORINSA BI\
CORINSA CPA:   C:\Users\naide\OneDrive\Documentos\Proyectos\CORINSA CPA\
ULTIMATE LABS: C:\Users\naide\OneDrive\Documentos\Proyectos\ULTIMATE LABS\
EMSULA DOCTOR: C:\Users\naide\OneDrive\Documentos\Proyectos\EMSULA DOCTOR\
NAI:           C:\Users\naide\OneDrive\Documentos\Proyectos\Nai\
```

### `/scan hoy` y `/scan semana`

1. Spawnear un subagente Haiku **por cliente** (7 agentes en paralelo)
2. Cada subagente recibe: lista de carpetas del cliente + filtro de fecha
3. Comando por repo: `git log --since="today" --oneline --format="%h %ad %an: %s" --date=short`
4. El subagente devuelve solo los repos que tuvieron actividad con sus commits
5. El agente principal ensambla el reporte agrupado por cliente

### `/scan [autor]`

1. Normalizar el nombre (case-insensitive, puede ser nombre parcial)
2. Un subagente Haiku por cliente, cada uno corre:
   `git log --author="[autor]" --since="30 days ago" --oneline --format="%h %ad %s" --date=short`
   en todos los repos del cliente
3. Ensamblar agrupado por proyecto, ordenado por fecha

### `/scan [alias]`

Resolver el alias desde `~/.claude/projects-registry.md`, luego correr en ese repo:
```
git fetch --quiet
git log --oneline -10 --format="%h %ad %an: %s" --date=short
git log HEAD..@{u} --oneline 2>/dev/null (commits remotos pendientes)
```
Usar un solo subagente Haiku para esto.

### `/scan pendientes`

Un subagente Haiku por cliente. Por cada repo: `git status --short` + `git log @{u}..HEAD --oneline 2>/dev/null`.
Solo reportar repos que tienen algo.

### `/scan atras`

Primero hacer `git fetch --all --quiet` en todos los repos (en paralelo, un Haiku por cliente).
Luego verificar: `git log HEAD..@{u} --oneline 2>/dev/null`.
Solo reportar repos que están detrás del remoto.

### Formato del reporte

```
=== /scan hoy — 13 jun 2026 ===

YALO (3 repos con actividad)
  yalo bo api  │ 2 commits
                │ abc1234 fix: endpoint de facturas
                │ def5678 feat: agregar campo descuento

LA BODEGA (1 repo con actividad)
  bodega ecommerce │ 1 commit
                    │ 9ef230c Edgardo: fix: prevenir freeze del navegador

Sin actividad: CORINSA, ULTIMATE LABS, EMSULA DOCTOR, NAI
```

### Límites para no explotar el contexto

- Máximo 10 commits por repo en el reporte
- Si un repo tiene más, indicar "+N commits más" y no listarlos todos
- No mostrar diffs — solo subject line del commit
- Si el usuario quiere el diff de algo específico, usar `/proyecto [alias]` o pedir explícitamente
