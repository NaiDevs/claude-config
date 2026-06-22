---
name: release
description: Use this skill for releases, deployments, production deploys, migration plans, environment variables, rollback plans, changelogs, post-deploy validation, deploy checklist, release branches, coordinating backend and frontend deploys, subir a producción, deploy, lanzamiento, migración en producción.
---

# /release

Workflow de release. Cubre checklist, coordinación, migraciones, variables de entorno y rollback.

## Cuándo usar

- Preparar un deploy a staging o producción
- Coordinar un release que incluye backend + frontend
- Revisar si hay migraciones pendientes antes de subir
- Documentar qué cambios van en el release
- Planificar un rollback si algo falla

## Loop de trabajo

```
1. Recopilar commits del release
   → git log origin/main..HEAD --oneline
   → Clasificar: feat, fix, breaking change, migration, config

2. Identificar riesgos
   → ¿Hay migraciones? → deben correr ANTES del deploy del código
   → ¿Hay variables de entorno nuevas? → configurar en el servidor primero
   → ¿Hay breaking changes en la API? → coordinar frontend y backend
   → ¿Cambios en configuración de servicios externos? (Firebase, AWS, etc.)

3. Checklist pre-deploy
   → Variables de entorno nuevas configuradas en el servidor
   → Migraciones revisadas y sin datos en riesgo
   → Tests pasando en CI
   → Build exitoso localmente
   → PR aprobado y mergeado

4. Orden de deploy
   → 1. Correr migraciones
   → 2. Deploy backend
   → 3. Validar backend (health check, endpoints críticos)
   → 4. Deploy frontend
   → 5. Validar frontend (flujos críticos)

5. Post-deploy validation
   → Health check del API
   → Login funcional
   → Operación crítica del release funcional
   → Monitorear logs por 10-15 minutos

6. Rollback si es necesario
   → Revertir el deploy del código
   → Si hay migraciones: decidir si revertir datos o mantener backwards-compatible
```

## Reglas

- Las migraciones van ANTES que el código que las requiere
- Variables de entorno nuevas van ANTES del deploy
- Nunca deployar sin build exitoso
- Si hay breaking changes en API: coordinar frontend y backend en el mismo deploy o versionar
- Documentar el rollback ANTES de deployar, no después de que falle

## Checklist pre-deploy

```
[ ] git log limpio — sin commits debug ni console.log
[ ] Variables de entorno nuevas documentadas y configuradas
[ ] Migraciones revisadas — no modifican datos existentes sin backup
[ ] Tests pasando (CI verde)
[ ] Build exitoso
[ ] PR aprobado
[ ] CHANGELOG actualizado
[ ] Hora del deploy coordinada con el equipo
[ ] Plan de rollback definido
```

## Checklist post-deploy

```
[ ] Health check OK
[ ] Login funcional
[ ] Flujo principal del release funcional
[ ] Logs sin errores nuevos
[ ] Métricas estables (si aplica)
[ ] Notificar al equipo que el deploy fue exitoso
```

## Plantilla de CHANGELOG

```markdown
## [1.x.x] — YYYY-MM-DD

### Agregado
- feat: descripción del feature nuevo

### Corregido
- fix: descripción del bug corregido

### Cambiado
- refactor: descripción del cambio

### Migraciones
- migration: descripción del cambio de schema

### Variables de entorno nuevas
- `NUEVA_VAR`: descripción de para qué sirve
```
