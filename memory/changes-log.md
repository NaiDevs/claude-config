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

- 2026-06-22 | YALO | bug | Identificado error en ejecución SQL: scaffold de EF Core ejecutó ALTER TABLE en tabla incorrecta (pro_categoriavariaciones); el target correcto es pro_categoriaproducto que mapea a ProCategoriaproducto.cs — solución: `ALTER TABLE pro_categoriaproducto ADD COLUMN activoecommerce boolean DEFAULT true;`
- 2026-06-22 | YALO | bug | EF Core scaffold chain issue: YaloCobroEntities sobrescribía ProCategoriaproducto.cs eliminando Activoecommerce; YaloAUTHEntities fallaba al buildear; solución: ALTER TABLE pro_categoriaproducto ADD COLUMN activoecommerce bool NULL (debe ejecutarse en BD DEV)
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
- 2026-06-22 | YALO | decision | Refactoring componentes ion-toggle → yalo-switch con margin-top: 16px para separación visual
- 2026-06-22 | YALO | config | ExternalService.CategoriesController: agregado filtro `category.Activoecommerce != false` en GetCategories para incluir categorías con NULL además de true (compatibilidad con datos pre-ALTER)
- 2026-06-22 | YALO | decision | Arquitectura de features ecommerce: requirement analysis — 3 funcionalidades (desactivar categorías en ecommerce, upload icono, desactivar productos); exploración de entidades ProCategoriaproducto y ProProducto; sistema S3 base64 documentado
- 2026-06-22 | YALO | decision | Componente categoria-detail: refactor final de checkboxes — uso de `yalo-checkbox` para Activo y ActivoEcommerce con margin-top 16px de separación visual; comentarios HTML para claridad ("Este producto está a la venta")
- 2026-06-22 | YALO | decision | Patrón de filtrado ecommerce: `!= false` en lugar de `== true` — permite que productos/categorías con NULL (creadas antes del ALTER) sigan visibles en ecommerce; solo se excluyen explícitamente los que tengan `activoecommerce = false`
- 2026-06-22 | YALO | feat | ProductsListService: aplicado filtro ecommerce idéntico a categorías — `query.Where(p => p.Activoecommerce != false)` post GetProductsQuery; manteniendo backward compatibility con datos legacy
- 2026-06-22 | YALO | feat | ProProducto.cs (ExternalService): agregada columna `public bool? Activoecommerce` para deshabilitar productos exclusivamente en ecommerce; nullable bool para datos pre-ALTER
- 2026-06-22 | YALO | bug | Sesión diagnóstico: dotnet build falla con errores de constructores en YaloCobroEntities; scaffold EF Core sobrescribió ProCategoriaproducto.cs y ProProducto.cs eliminando campos Activoecommerce; solución: `dotnet clean; dotnet build` para limpiar caché de compilación
- 2026-06-22 | YALO | bug | PowerShell 5.1 issue: `Invoke-Expression` intercepta stderr de dotnet EF scaffold (convierte warnings a ErrorRecords); solución: reemplazar con call operator `& dotnet @scaffoldArgs` (array de argumentos) en both YALO-API-ExternalService/context.ps1 y YaloPOSBackofficeAPI/YaloApi/context.ps1
- 2026-06-22 | YALO | config | TaxesPedidosService: refactor DI — recibe DbContext (YaloCobroEntities) por constructor en lugar de crear con `new`; AddScoped registrado correctamente; scaffold EF no rompe inyección porque context se pasa desde afuera
- 2026-06-22 | YALO | config | Commits preparados: 4 cambios listos para subir — YaloPOSBackofficeAPI (feat/naidelyn/promos: campo activoecommerce + controles UI), YALO-ExternalService y YALO-API-ExternalService (filtro ecommerce); .gitignore actualizado agregando .idea
- 2026-06-22 | YALO | config | Merge + Push sincronizado: YALO-ExternalService labodega-dev integró 4 commits remotos (Coupons: BulkCouponRules, CouponsV2Controller, DTO, PedidosRepositories); push exitoso a GitHub y Azure remotes (commit 89330e3)
- 2026-06-22 | YALO | decision | Vista de calificación por producto: entidad `VwProductosPromedioCalificacion.cs` generada por último scaffold EF Core en repos externos; requiere integración en consultas de productos para exponer promedio de ratings
- 2026-06-22 | YALO | feat | ExternalService.CategoriesController: patrón de filtrado ecommerce consolidado con `category.Activoecommerce != false` — permite compatibilidad backward con datos NULL (creados pre-ALTER); solo excluye explícitamente false
- 2026-06-22 | YALO | bug | TerritorioCliente: API ListaClientes ahora incluye CodCliente; tipo TerritorioCliente con FormArray opcional (ListaClientes?: ClienteResult[]); componente addTerritorioCliente puebla FormArray con clientes existentes al cargar territorio
- 2026-06-22 | YALO | feat | ProductsListService: filtro ecommerce sincronizado con categorías — `p.Activoecommerce != false` aplicado en GetProductsQuery; mantiene datos legacy visibles en ecommerce
- 2026-06-22 | YALO | decision | Arquitectura de features ecommerce: exploración completa de YaloPOSBackoffice (Angular) + YaloPOSBackofficeAPI — identificados puntos de integración (info-general-producto, CategoriaProductosModel); sistema S3 base64 documentado
- 2026-06-22 | YALO | bug-fix | EF Core scaffold chain: PowerShell 5.1 issue corregido — reemplazar `Invoke-Expression` con call operator `&` para evitar que stderr de dotnet se convierta en ErrorRecords; aplicado en context.ps1 de ambos repos
- 2026-06-22 | YALO | config | Intento de activar workspace con 3 repos (yalo bo api, yalo bo fe, yalovendo api) — bloqueado por modo don't ask; necesita habilitar permisos PowerShell/Bash para verificar git status
- 2026-06-22 | YALO | config | Activación exitosa de workspace "yalo bo extended": yalovendo api (branch fix/naidelyn/entrego, último commit 2026-06-15), yalo bo fe (branch feat/naidelyn/yalovendo, último commit 2026-06-01), yalo bo api (branch feat/naidelyn/yalovendo, último commit 2026-06-01, archivo YaloApi/context.ps1 sin trackear)
- 2026-06-22 | YALO | bug | YaloVendoEntrego: WhatsApp automático enviado a cliente al crear pedido — ahora solo se envía si se pasa `phoneNumber` en el body; si falta número retorna sin consultar DB ni enviar mensaje (validación temprana en TryNotifyOrderCreatedWhatsAppAsync línea 848)
- 2026-06-22 | YALO | feat | Feature Territorios de Empleados por Cliente: Backend (YaloPOSBackofficeAPI): TerritorioClienteModel + TerritorioClientesController (GET/PUT endpoints) + LiquidacionesController (filtro territorios); Frontend (YaloPOSBackoffice): rutas, service, componente territorio-cliente-detail, selector de territorio en cliente-detail; pendiente: ejecutar script SQL para tabla emp_empleadosxterritorio
- 2026-06-23 | YALO | general | Ajuste UI componente territorio-cliente-detail: bloque "Empleados del territorio" movido dentro del formBody después del nombre y antes de los clientes asignados — utilizando `yalo-select-multiple` en lugar de `yalo-select`; imports limpios (eliminado MultiSelectComponent del módulo)
- 2026-06-23 | YALO | decision | Refactor de relación cliente-empleado: eliminación de columnas `codempleadopreventista` y `codempleadorepartidor` de tabla `cli_clientes`; miración a modelo basado en territorios — empleados se asignan por territorio y no directamente al cliente; actualización de componente territorio-cliente-detail con flag `employeesChanged = false`
