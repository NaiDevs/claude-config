---
name: debug
description: Use this skill for bugs, errors, exceptions, failing tests, broken endpoints, incorrect API responses, duplicated records, query errors, authentication problems, authorization failures, frontend bugs, backend crashes, TypeScript errors, unexpected behavior, no funciona, falla, error, excepcion, respuesta incorrecta.
---

# /debug

Workflow de debugging estructurado. Sigue el flujo causa raíz → fix mínimo, sin refactorizar lo que no está roto.

## Cuándo usar

- Endpoint retorna 500, 401, 403, 404 inesperado
- Tests fallan o pasan cuando no deberían
- Datos duplicados, nulos o incorrectos en la DB
- Error TypeScript que bloquea compilación
- Comportamiento inesperado en el frontend (consola, red, estado)
- Excepción en producción / logs de error
- "No funciona" sin más contexto

## Triggers

`bug`, `error`, `exception`, `falla`, `no funciona`, `roto`, `duplicado`, `respuesta incorrecta`, `401`, `403`, `500`, `undefined`, `null`, `cannot read`, `is not a function`, `TypeScript error`, `test falla`

## Loop de trabajo

```
1. Entender/reproducir el error
   → leer el stack trace completo
   → reproducir localmente si es posible
   → identificar el request/acción que lo dispara

2. Seguir el flujo
   → Controller → Service → Repository (backend)
   → Component → Service → HTTP (frontend)
   → identificar en qué capa falla

3. Causa raíz
   → ¿datos incorrectos? ¿lógica rota? ¿tipado incorrecto?
   → ¿side effect? ¿race condition? ¿falta validación?

4. Fix mínimo
   → tocar solo lo necesario
   → NO refactorizar mientras se debuggea

5. Validar
   → reproducir el caso original → debe pasar
   → verificar casos relacionados → no deben romperse

6. Documentar
   → causa raíz en una línea
   → qué se cambió y por qué
```

## Reglas

- Leer el error completo antes de proponer soluciones
- No asumir la causa — verificar primero
- Fix mínimo: no cambiar lo que no está relacionado con el bug
- Si hay múltiples bugs, resolverlos uno a uno
- Si el bug es en datos (DB), no modificar datos en producción sin backup
- Ante error TypeScript: no usar `any` para silenciarlo — tiparlo correctamente
- Ante error 401/403: revisar guards, token y permisos antes de tocar lógica de negocio

## Ejemplos

**Backend — error 500:**
```
/debug
Stack trace: TypeError: Cannot read properties of undefined (reading 'id')
  at OrganizacionService.findOne (organizacion.service.ts:45)
```
→ Identifica que `repo.findOneBy` retorna `null` y hay acceso sin null check.
→ Fix: agregar `if (!entity) throw new NotFoundException(...)` antes de usar la entidad.

**Frontend — respuesta inesperada:**
```
/debug
El listado de facturas muestra undefined en el campo 'total'
```
→ Revisa la interfaz TypeScript, el response del endpoint y el mapeo en el servicio.
→ Compara el tipo esperado vs el tipo real del backend.

**Query duplicada:**
```
/debug
La query de pedidos devuelve filas duplicadas con JOIN a detalle_pedido
```
→ Identifica que el JOIN sin DISTINCT multiplica filas.
→ Fix: agregar `.distinct(true)` o reestructurar el query builder.

**TypeScript:**
```
/debug
TS2345: Argument of type 'string | undefined' is not assignable to parameter of type 'string'
```
→ Identifica la fuente del posible `undefined`.
→ Fix: narrowing con `if`, non-null assertion justificada, o cambiar el tipo del parámetro.
