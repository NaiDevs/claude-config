---
name: performance
description: Use this skill for performance optimization, slow queries, N+1 queries, missing indexes, slow API endpoints, high memory usage, lazy loading, caching, Redis, pagination optimization, slow frontend, Angular performance, bundle size, query optimization, respuesta lenta, query lenta, N+1, caché, optimización.
---

# /performance

Workflow para identificar y resolver problemas de performance en backend y frontend.

## Cuándo usar

- Endpoint tarda más de 1-2 segundos sin justificación
- Query SQL lenta (> 200ms en desarrollo)
- N+1 queries detectadas en logs
- Alto uso de memoria en el servidor
- Frontend carga lenta o tiene lag notable en interacciones
- Reportes o exports que tardan demasiado

## Loop de trabajo

```
1. Medir antes de optimizar
   → ¿Cuánto tarda ahora? (con números exactos)
   → ¿Dónde está el cuello de botella? (DB, CPU, red, frontend)
   → EXPLAIN ANALYZE para queries, logs para backend

2. Identificar el problema
   → N+1: queries dentro de loops → resolver con JOIN/eager
   → Índice faltante: Seq Scan en EXPLAIN
   → Datos excesivos: retornar 10.000 rows cuando necesita 25
   → No cachear: calcular lo mismo múltiples veces

3. Aplicar el fix específico
   → Sin over-engineering: la solución más simple que funcione

4. Medir después
   → ¿Mejoró el tiempo medido?
   → ¿No se rompió nada?
```

## Problemas y soluciones comunes

**N+1 queries (TypeORM):**
```typescript
// PROBLEMA ❌ — 1 query para pedidos + N queries para clientes
const pedidos = await pedidoRepo.find();
for (const pedido of pedidos) {
  const cliente = await clienteRepo.findOneBy({ id: pedido.clienteId }); // ← N+1
}

// SOLUCIÓN ✓ — 1 query con JOIN
const pedidos = await pedidoRepo.find({
  relations: { cliente: true },  // o leftJoinAndSelect en QueryBuilder
});
```

**Paginación faltante:**
```typescript
// PROBLEMA ❌ — carga toda la tabla
const datos = await repo.find();

// SOLUCIÓN ✓ — paginar siempre
const [datos, total] = await repo.findAndCount({
  take: limit,
  skip: (page - 1) * limit,
  order: { createdAt: 'DESC' },
});
```

**Índice faltante:**
```sql
-- Diagnóstico en PostgreSQL
EXPLAIN ANALYZE SELECT * FROM facturas WHERE cliente_id = 123;
-- → Seq Scan on facturas indica que no hay índice

-- Fix: agregar índice
CREATE INDEX CONCURRENTLY idx_facturas_cliente_id ON facturas(cliente_id);
-- Con TypeORM:
@Index(['clienteId'])
export class Factura { ... }
```

**Caching con Redis:**
```typescript
// Para datos que cambian poco y se leen mucho
@Injectable()
export class CatalogosService {
  constructor(
    private readonly redis: Redis,
    private readonly repo: Repository<Catalogo>,
  ) {}

  async findAll(): Promise<Catalogo[]> {
    const cached = await this.redis.get('catalogos:all');
    if (cached) return JSON.parse(cached);

    const data = await this.repo.find({ order: { nombre: 'ASC' } });
    await this.redis.setex('catalogos:all', 300, JSON.stringify(data)); // TTL 5 min
    return data;
  }

  async invalidateCache(): Promise<void> {
    await this.redis.del('catalogos:all');
  }
}
```

**Frontend — Angular lazy loading:**
```typescript
// PROBLEMA ❌ — todo en el bundle principal
const routes = [
  { path: 'reportes', component: ReportesComponent },
];

// SOLUCIÓN ✓ — lazy loading por módulo
const routes = [
  {
    path: 'reportes',
    loadComponent: () => import('./reportes/reportes.component').then(m => m.ReportesComponent),
  },
];
```

**Select específico (no SELECT *):**
```typescript
// PROBLEMA ❌ — carga todas las columnas incluyendo textos largos
const facturas = await repo.find();

// SOLUCIÓN ✓ — solo las columnas necesarias para el listado
const facturas = await repo
  .createQueryBuilder('f')
  .select(['f.id', 'f.numero', 'f.total', 'f.estado', 'f.createdAt'])
  .leftJoin('f.cliente', 'c')
  .addSelect(['c.nombre'])
  .getMany();
```
