---
name: changes-log
description: Log de commits y PRs realizados por proyecto — referencia rápida de qué se trabajó recientemente
metadata: 
  node_type: memory
  type: project
  originSessionId: baa97b0f-6550-4a98-92f2-501e6aea9d37
---

Registro cronológico de cambios. Cada entrada: `fecha | alias | tipo | descripción`.
Máximo 100 entradas — las más antiguas se eliminan cuando se supera ese límite.

<!-- formato: - YYYY-MM-DD | alias | commit/pr | descripción -->

- 2026-06-22 | YALO | bug | DbContext namespace corregido (context.ps1: $namespace.DB.$contextName); YaloCobroEntities.cs y ProCategoriaproducto.cs restaurados; build limpio
- 2026-06-22 | YALO | bug | EF Core scaffold sobrescribió ProCategoriaproducto.cs borrando campo Activoecommerce; build falló con 6 errores — diagnosticado con Select-String para aislar errores vs warnings
- 2026-06-22 | YALO | config | Scaffolding EF Core: YaloApi/context.ps1 — agregado `--schema public` para excluir schemas problemáticos (aws_sqlserver_ext, pgmail)
- 2026-06-22 | YALO | config | Scaffolding EF Core: YaloApi/context.ps1 genera YaloCobroEntities y YaloAUTHEntities con todas las tablas, credenciales dev integradas; .gitignore actualizado
- 2026-06-22 | YALO | feat | Feature ecommerce exclusivo: columnas activoecommerce (nullable BIT) en pro_categoriaproducto y pro_producto; entidades C# con bool?; disable categorías y productos solo para ecommerce
- 2026-06-21 | engram | config | Integración de agente Engram en hook Stop — sincronización automática de sesiones
- 2026-06-21 | engram | bug-fix | Hooks no guardaban correctamente en Engram — agregado agente de persistencia
- 2026-06-21 | agent-ai-config | feat | Hook Stop completo: on-session-stop.ps1 + agent Engram + fix filtros PostToolUse sin 'if'
- 2026-06-21 | agent-ai-config | feat | setup.ps1 actualizado: despliega stop hook para Claude Code y Codex, CLAUDE.md sincronizado
- 2026-06-21 | agent-ai-config | feat | Engram agent hook: rutea a Clientes/ y Decisiones/ segun tipo de sesion (DECISION/BUG/CONFIG)
- 2026-06-21 | agent-ai-config | refactor | Elimina integracion Obsidian de hooks — Engram (changes-log.md) queda como unico sistema automatico
- 2026-06-21 | NAI | config | Configuración de agent Stop hook para Engram — sincronización de cambios con memoria de Obsidian
- 2026-06-21 | NAI | config | Engram detecta proyecto activo por rutas del transcript — escanea tool calls (Read/Write/Edit/Bash) para mapear a clientes
- 2026-06-21 | agent-ai-config | commit | chore(tooling): auditoria completa — doctor, uninstall, tests, readme, fixes
- 2026-06-21 | NAI | config | Setup audit completo: doctor.ps1, uninstall.ps1, setup.validation.tests.ps1, CHANGELOG, README refactor, .gitattributes
- 2026-06-21 | NAI | bug | Corregido bug de triplicación en MEMORY.md — setup.ps1 no hace append posterior al Copy-Item
- 2026-06-21 | NAI | config | Cleanup de archivos obsoletos: hooks/on-session-stop.ps1, tmp/hook-test.txt, .last-update.log removidos del tracking
- 2026-06-21 | agent-ai-config | commit | feat(mcps): agrega Redis, Playwright y tabla cloud vs local
- 2026-06-21 | NAI | config | setup.ps1: auto-detección Redis NOMBRE_REDIS → MCP redis-nombre en mcp.json + config.toml; Playwright agregado como @playwright/mcp
- 2026-06-21 | NAI | config | mcp.env.example: plantillas limpias con convención _DEV/_SS/_REDIS; README: tabla 22 servicios + MCPs obligatorios/recomendados/opcionales; doctor.ps1: validación local sin exponer secretos
