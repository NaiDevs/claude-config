---
name: review
description: Use this skill for code review, reviewing pull requests, reviewing changes, checking code quality, architecture violations, naming conventions, missing validations, security issues in code, TypeScript problems, NestJS patterns, Angular patterns, reviewing a diff, revisar código, code review, PR review.
---

# /review

Workflow de code review. Revisa calidad, arquitectura, seguridad y correctitud sin refactorizar todo.

## Cuándo usar

- Revisar un PR antes de merge
- Revisar código que acabás de escribir (self-review)
- Revisar código de un compañero
- Detectar problemas antes de un deploy

## Loop de trabajo

```
1. Entender el cambio
   → ¿Qué se modificó? ¿por qué?
   → Leer el diff completo antes de comentar

2. Verificar arquitectura
   → Controller solo maneja HTTP (no lógica de negocio)
   → Service contiene lógica (no accede a repo directamente si hay Repository)
   → Repository solo maneja DB
   → Sin lógica en templates Angular

3. Verificar correctitud
   → Casos edge: null, undefined, arreglo vacío, paginación sin datos
   → Tipos correctos — sin 'any' injustificado
   → Validaciones en DTOs completas

4. Verificar seguridad
   → Endpoints protegidos con guards
   → Sin secretos hardcodeados
   → Sin SQL concatenado (inyección)
   → Sin datos sensibles en logs

5. Verificar calidad
   → Nombres claros y consistentes
   → Sin código comentado ni console.log
   → Imports ordenados, sin imports no usados
   → Sin duplicación obvia

6. Documentar hallazgos
   → [BLOCKER] problemas que impiden merge
   → [WARN] problemas que deberían corregirse
   → [NOTE] sugerencias opcionales
```

## Reglas

- Separar observaciones por severidad: BLOCKER / WARN / NOTE
- No pedir cambios de estilo en PRs de funcionalidad — si no hay linter configurado, eso va aparte
- No refactorizar todo si el cambio es pequeño — enfocarse en lo que cambió
- Un BLOCKER justifica no aprobar; un NOTE no

## Checklist rápido

```
[ ] Controller no tiene lógica de negocio
[ ] Service no accede a la DB directamente (usa repo)
[ ] DTOs con validaciones class-validator
[ ] Endpoints protegidos con guards
[ ] Sin console.log en el código final
[ ] Sin 'any' injustificado
[ ] Sin secretos hardcodeados
[ ] Manejo de errores (NotFoundException, BadRequestException, etc.)
[ ] Swagger documentado en endpoints nuevos
[ ] Tests para la lógica nueva (si el proyecto los tiene)
[ ] Sin N+1 queries obvias
[ ] Migraciones incluidas si hay cambio de schema
```
