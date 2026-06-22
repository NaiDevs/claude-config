---
name: architect
description: Use this skill for architecture decisions, system design, module structure, service design, database schema design, API design, scalability, new feature planning, refactoring planning, technical decisions, NestJS architecture, Angular architecture, arquitectura, diseño de sistema, estructura de módulos, decisión técnica.
---

# /architect

Workflow para decisiones de arquitectura y diseño de nuevas features. Propone un plan corto antes de implementar.

## Cuándo usar

- Diseñar un feature nuevo de mediana o alta complejidad
- Decidir entre dos enfoques técnicos
- Planificar cómo agregar un módulo sin romper lo existente
- Decidir el schema de una tabla nueva
- Diseñar un contrato API antes de implementarlo

## Loop de trabajo

```
1. Entender el requerimiento
   → ¿Qué problema resuelve? ¿qué usuario lo usa?
   → ¿Qué datos maneja? ¿qué reglas de negocio?
   → ¿Qué integra con sistemas existentes?

2. Inspeccionar lo existente
   → ¿Hay patrones similares en el proyecto?
   → ¿Hay entidades o servicios reutilizables?
   → ¿Hay constraints del schema actual?

3. Proponer estructura
   → Módulos y sus responsabilidades
   → Entidades y relaciones
   → Contratos de API (endpoints, DTOs)
   → Dependencias entre módulos

4. Identificar riesgos
   → ¿Rompe algo existente?
   → ¿Requiere migración de datos?
   → ¿Hay performance concerns?

5. Decisión y justificación
   → Recomendar un enfoque con justificación
   → Listar trade-offs del enfoque elegido
   → Identificar lo que NO se implementa ahora (out of scope)
```

## Reglas

- Respetar Controller → Service → Repository — no saltear capas
- Módulos acoplados por interfaces, no por implementación directa
- Schema: fields mínimos necesarios, agregar después es más fácil que quitar
- APIs: empezar por el contrato (request/response) antes de la implementación
- Documentar la decisión en memoria Engram si es importante

## Principios del stack

```
NestJS:
  Módulo = unidad de funcionalidad (facturas, clientes, pagos)
  Controller = solo HTTP (recibir, validar, delegar, retornar)
  Service = lógica de negocio (reglas, transformaciones, orquestación)
  Repository = acceso a datos (queries, CRUD, transacciones)

Angular:
  Componente = UI + interacción (no lógica de negocio)
  Servicio = estado + HTTP (no presentación)
  Guard = acceso + redirección
  Interfaces = contratos (no clases si no hay lógica)
```
