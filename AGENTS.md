# AGENTS.md — Instrucciones globales para Codex

## Arquitectura de referencia

```
NestJS Backend:
  Controller → recibe HTTP, valida, delega al Service, retorna respuesta
  Service    → lógica de negocio, reglas, orquestación
  Repository → acceso a datos (TypeORM), queries, CRUD, transacciones

Angular Frontend:
  Component  → UI, interacción de usuario (no lógica de negocio)
  Service    → estado, HTTP, lógica compartida
  Guard      → acceso a rutas, redirección
```

## Reglas de código

- **TypeScript**: tipos explícitos siempre. Nunca `any` salvo interop inevitable.
- **NestJS**: standalone false (usa módulos); `inject()` en constructors.
- **Angular 15+**: `standalone: true` en todos los componentes.
- **Angular DI**: usar `inject()` — no constructor DI en Angular 14+.
- **Formularios Angular**: siempre `ReactiveFormsModule`, no Template-driven en forms complejos.
- **Async**: siempre `async/await`. Nunca callbacks ni `.then()` encadenado (solo cuando es necesario).
- **Logging**: nunca `console.log` — usar el logger del framework (Logger de NestJS, etc.).
- **Comentarios**: solo comentar el POR QUÉ si no es obvio. No comentar qué hace el código.

## Skills disponibles

Activa el skill correspondiente cuando detectes estas palabras clave:

| Palabras clave detectadas | Skill |
|---|---|
| NestJS, @Module, @Controller, @Injectable, DTO | `/nestjs` |
| TypeORM, @Entity, @Column, QueryBuilder, migration | `/typeorm` |
| Angular, componente, servicio Angular, guard Angular | `/angular` |
| Angular Material, mat-table, mat-dialog, mat-form-field | `/material` |
| PDFKit, generar PDF, reporte PDF, factura PDF | `/pdfkit` |
| Firebase, FCM, push notification, firebase-admin | `/firebase-fcm` |
| JWT, auth, guard, roles, permisos, 403 | `/permissions` |
| API, endpoint, DTO, contrato, Swagger, OpenAPI | `/api-contract` |
| migración DB, migration TypeORM, agregar columna | `/migration` |
| debug, error, excepción, bug, no funciona | `/debug` |
| SQL lenta, N+1, índice, EXPLAIN, query lenta | `/db-audit` |
| performance, optimización, caché, Redis | `/performance` |
| arquitectura, diseño, módulo nuevo, feature nueva | `/architect` |
| refactor, duplicación, extraer servicio | `/refactor` |
| release, deploy, CHANGELOG | `/release` |
| hotfix, urgente, rollback | `/hotfix` |
| review, code review, revisar código | `/review` |
| seguridad, OWASP, SQL injection, IDOR | `/security` |
| validar proyecto, dependencias faltantes, .env | `/doctor` |

## Memoria Engram

Los archivos de memoria están en `~/.codex/memory/`. Consultar antes de responder sobre proyectos.

- `MEMORY.md` — índice de memorias
- `projects-yalo.md` — proyectos YALO (POS, pagos)
- `projects-labodega.md` — proyectos La Bodega (ecommerce)
- `projects-corinsa.md` — proyectos CORINSA (BI/CPA)
- `user-profile.md` — perfil de la usuaria

## Estilo de respuesta

- Respuestas cortas y directas. Sin introducciones largas.
- Sin resumir al final lo que ya se hizo.
- Código en español para nombres de variables/métodos si el proyecto lo usa así.
- Commits, PRs y documentación: en español.
