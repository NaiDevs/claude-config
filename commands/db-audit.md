---
name: db-audit
description: Use this skill for database analysis, SQL joins, duplicate rows, missing rows, wrong counts, cardinality problems, indexes, query performance, PostgreSQL, SQL Server, TypeORM queries, EF Core queries, views, stored procedures, data validation, consulta SQL, query lenta, duplicados en base de datos, datos incorrectos.
---

# /db-audit

Análisis y auditoría de queries, datos y estructura de base de datos. PostgreSQL y SQL Server.

## Cuándo usar

- Query retorna datos incorrectos, duplicados o nulos
- Conteos no coinciden entre pantalla y DB
- Query lenta o sin índices
- Validar integridad de datos antes de un deploy
- Revisar relaciones y cardinalidad de una tabla nueva
- Analizar diferencias entre dos entornos (dev vs prod)
- Investigar un problema de datos reportado por el cliente

## Triggers

`duplicate rows`, `datos duplicados`, `query lenta`, `missing rows`, `conteo incorrecto`, `JOIN`, `índice`, `index`, `performance`, `audit`, `validar datos`, `integridad`, `SQL`, `EXPLAIN`, `cardinality`, `null rows`, `vistas`, `stored procedure`

## Loop de trabajo

```
1. Entender el negocio
   → ¿Qué dato debe existir? ¿Qué relaciones tiene?
   → ¿Cuál es el resultado esperado vs el real?

2. Identificar tablas y vistas involucradas
   → Revisar entidades TypeORM / esquema DB
   → Identificar FK, nullables, soft deletes

3. Revisar relaciones y cardinalidad
   → ¿1:N o N:M puede multiplicar filas en JOIN?
   → ¿Hay soft-deleted records en el conjunto?

4. Escribir query de diagnóstico
   → Empezar sin JOINs, ir agregando de a uno
   → Verificar conteos en cada paso

5. Validar duplicados y nulos
   → GROUP BY + HAVING COUNT > 1 para duplicados
   → IS NULL checks en columnas críticas

6. Revisar performance
   → EXPLAIN ANALYZE (PostgreSQL) o SET STATISTICS IO ON (SQL Server)
   → Proponer índices si falta o están mal

7. Integrar la corrección
   → Query corregida en TypeORM / raw SQL
   → Migration si hay cambio de esquema
```

## Reglas

- **Nunca hacer UPDATE/DELETE en producción sin backup y sin WHERE acotado**
- Siempre verificar conteos antes y después de un cambio de datos
- Verificar si la tabla usa soft delete (`deleted_at`) — puede afectar los conteos
- En PostgreSQL: usar `EXPLAIN ANALYZE` para queries lentas
- En SQL Server: usar `SET STATISTICS IO, TIME ON`
- Al investigar duplicados: identificar primero el campo que los distingue
- No asumir que un JOIN es correcto — verificar la cardinalidad

## Ejemplos

**Duplicados por JOIN:**
```sql
-- Diagnóstico: ¿cuántas filas produce el JOIN?
SELECT p.id, COUNT(*) as total
FROM pedidos p
JOIN detalle_pedido d ON d.pedido_id = p.id
GROUP BY p.id
HAVING COUNT(*) > 1;
-- → Si hay N detalles por pedido, el JOIN N-multiplica las filas del pedido
-- Fix: mover el JOIN a la subconsulta o usar LEFT JOIN con agregación
```

**Conteo incorrecto con soft delete:**
```sql
-- Con TypeORM y @DeleteDateColumn:
-- .find() excluye soft-deleted por defecto
-- .createQueryBuilder() los INCLUYE a menos que tengas .where('deleted_at IS NULL')
SELECT COUNT(*) FROM organizaciones WHERE deleted_at IS NULL;
```

**Índice faltante:**
```sql
EXPLAIN ANALYZE
SELECT * FROM facturas WHERE cliente_id = 123 AND estado = 'pendiente';
-- → Seq Scan indica falta de índice
-- Fix:
CREATE INDEX CONCURRENTLY idx_facturas_cliente_estado
ON facturas(cliente_id, estado)
WHERE deleted_at IS NULL;
```

**Integridad referencial:**
```sql
-- Detectar facturas sin cliente válido (FK sin constraint)
SELECT f.id, f.cliente_id
FROM facturas f
LEFT JOIN clientes c ON c.id = f.cliente_id
WHERE c.id IS NULL;
```

**TypeORM — validar query generada:**
```typescript
// Ver el SQL generado antes de ejecutar
const query = this.repo
  .createQueryBuilder('f')
  .leftJoinAndSelect('f.cliente', 'c')
  .where('f.estado = :estado', { estado: 'pendiente' });

console.log(query.getSql()); // inspeccionar antes de .getMany()
```
