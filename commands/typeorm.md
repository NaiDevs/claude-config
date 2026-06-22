---
name: typeorm
description: Use this skill for TypeORM entities, repositories, relations, QueryBuilder, DataSource, TypeORM migrations, @Entity, @Column, @PrimaryGeneratedColumn, @ManyToOne, @OneToMany, @ManyToMany, @JoinColumn, @Index, Repository<T>, findAndCount, createQueryBuilder, leftJoinAndSelect, TypeORM 0.3.x, NestJS TypeORM integration, crear entidad TypeORM, crear repositorio TypeORM, query TypeORM, relación TypeORM.
---

# typeorm

Asistente para TypeORM 0.3.x en proyectos NestJS. Genera entidades, repositorios personalizados, relaciones, migrations y queries con QueryBuilder siguiendo los patrones reales de La Bodega y YALO Admin.

## Uso

```
/typeorm entity <nombre>              → entidad completa con decoradores
/typeorm relation <tipo> <A> <B>      → relación entre dos entidades
/typeorm repo <nombre>                → repositorio personalizado con métodos comunes
/typeorm migration <nombre>           → genera/corre migrations
/typeorm query <descripción>          → QueryBuilder para el caso de uso
/typeorm datasoruce                   → genera o revisa el DataSource del proyecto
/typeorm seed <nombre>                → seeder con datos de prueba
/typeorm subscriber <nombre>          → subscriber para eventos de entidad
/typeorm index <entidad> <columnas>   → agrega índices a una entidad
/typeorm fix                          → detecta problemas comunes de TypeORM
```

## Contexto de proyectos

| Alias | Proyecto | DB | TypeORM |
|---|---|---|---|
| bodega bo api | LaBodegaBOAPI | PostgreSQL | 0.3.24 |
| bodega services | LaBodegaServices | PostgreSQL | 0.3.24 |
| yalo admin api | YALO_API_Administrator | PostgreSQL + Supabase | 0.3.24 |
| nai restaurant api | inHandsRestauranteApi | PostgreSQL | 0.3.28 |

---

## Generadores

### `/typeorm entity <nombre>`

Entidad completa con todos los decoradores necesarios:

```typescript
// src/<nombre>s/entities/<nombre>.entity.ts
import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, UpdateDateColumn, DeleteDateColumn,
  Index, BeforeInsert, BeforeUpdate
} from 'typeorm';

@Entity('<nombre>s')
@Index(['nombre'])
export class <Nombre> {
  @PrimaryGeneratedColumn()
  id: number;

  // Columna de texto requerida
  @Column({ type: 'varchar', length: 255 })
  nombre: string;

  // Columna opcional
  @Column({ type: 'text', nullable: true })
  descripcion?: string;

  // Número decimal (precios, montos)
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  monto: number;

  // JSONB (datos dinámicos)
  @Column({ type: 'jsonb', nullable: true })
  metadata?: Record<string, any>;

  // Enum
  @Column({
    type: 'enum',
    enum: ['activo', 'inactivo', 'pendiente'],
    default: 'activo'
  })
  estado: 'activo' | 'inactivo' | 'pendiente';

  // Boolean con default
  @Column({ default: true })
  activo: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @DeleteDateColumn({ name: 'deleted_at' })
  deletedAt?: Date;  // soft delete automático
}
```

Preguntar qué columnas necesita antes de generar. Incluir solo las relevantes.

---

### `/typeorm relation <tipo> <A> <B>`

#### OneToMany / ManyToOne

```typescript
// Entidad A (padre, ej: Cliente)
@OneToMany(() => Pedido, (pedido) => pedido.cliente, {
  cascade: true,       // guardar/actualizar hijos automáticamente
  eager: false,        // no cargar automáticamente (usar JOIN explícito)
})
pedidos: Pedido[];

// Entidad B (hijo, ej: Pedido)
@ManyToOne(() => Cliente, (cliente) => cliente.pedidos, {
  onDelete: 'CASCADE',  // eliminar hijos si se elimina el padre
  nullable: false,
})
@JoinColumn({ name: 'cliente_id' })
cliente: Cliente;

@Column({ name: 'cliente_id' })
clienteId: number;
```

#### ManyToMany (con tabla intermedia automática)

```typescript
// Entidad A (ej: Producto)
@ManyToMany(() => Categoria, (categoria) => categoria.productos, {
  cascade: true,
})
@JoinTable({
  name: 'producto_categorias',
  joinColumn: { name: 'producto_id', referencedColumnName: 'id' },
  inverseJoinColumn: { name: 'categoria_id', referencedColumnName: 'id' },
})
categorias: Categoria[];

// Entidad B (ej: Categoria)
@ManyToMany(() => Producto, (producto) => producto.categorias)
productos: Producto[];
```

#### ManyToMany con datos extra en la tabla intermedia

```typescript
// Tabla intermedia como entidad propia
@Entity('pedido_productos')
export class PedidoProducto {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Pedido, (p) => p.pedidoProductos)
  @JoinColumn({ name: 'pedido_id' })
  pedido: Pedido;

  @ManyToOne(() => Producto)
  @JoinColumn({ name: 'producto_id' })
  producto: Producto;

  @Column({ type: 'int', default: 1 })
  cantidad: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  precioUnitario: number;
}
```

#### OneToOne

```typescript
// Entidad A (ej: Usuario)
@OneToOne(() => Perfil, (perfil) => perfil.usuario, { cascade: true })
@JoinColumn({ name: 'perfil_id' })
perfil: Perfil;

// Entidad B (ej: Perfil)
@OneToOne(() => Usuario, (usuario) => usuario.perfil)
usuario: Usuario;
```

---

### `/typeorm repo <nombre>`

Repositorio personalizado con métodos de búsqueda comunes:

```typescript
// src/<nombre>s/repositories/<nombre>.repository.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, FindOptionsWhere, ILike, Between } from 'typeorm';
import { <Nombre> } from '../entities/<nombre>.entity';

@Injectable()
export class <Nombre>Repository {
  constructor(
    @InjectRepository(<Nombre>)
    private readonly repo: Repository<<Nombre>>,
  ) {}

  // Buscar con paginación
  async findPaginated(
    page: number,
    limit: number,
    where?: FindOptionsWhere<<Nombre>>,
  ) {
    const [data, total] = await this.repo.findAndCount({
      where,
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
      withDeleted: false,
    });
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  // Buscar por texto (ILIKE — case insensitive en PostgreSQL)
  findByNombre(texto: string) {
    return this.repo.find({
      where: { nombre: ILike(`%${texto}%`) },
      order: { nombre: 'ASC' },
    });
  }

  // Buscar con relaciones
  findWithRelations(id: number) {
    return this.repo.findOne({
      where: { id },
      relations: { relacion: true },
    });
  }

  // Soft delete (requiere @DeleteDateColumn en la entidad)
  softDelete(id: number) {
    return this.repo.softDelete(id);
  }

  // Restore después de soft delete
  restore(id: number) {
    return this.repo.restore(id);
  }

  // Upsert
  upsert(data: Partial<<Nombre>>, conflictPaths: (keyof <Nombre>)[]) {
    return this.repo.upsert(data, { conflictPaths });
  }

  // Bulk insert
  bulkInsert(items: Partial<<Nombre>>[]) {
    return this.repo
      .createQueryBuilder()
      .insert()
      .into(<Nombre>)
      .values(items)
      .orIgnore()  // ignorar duplicados
      .execute();
  }
}
```

Registrar en el módulo:
```typescript
@Module({
  imports: [TypeOrmModule.forFeature([<Nombre>])],
  providers: [<Nombre>Service, <Nombre>Repository],
  exports: [<Nombre>Repository],
})
export class <Nombre>Module {}
```

---

### `/typeorm query <descripción>`

#### QueryBuilder — patrones comunes

**Con JOIN y filtros dinámicos:**
```typescript
async findFiltered(filters: {
  nombre?: string;
  estado?: string;
  fechaDesde?: Date;
  fechaHasta?: Date;
  page?: number;
  limit?: number;
}) {
  const { page = 1, limit = 25 } = filters;

  const qb = this.repo
    .createQueryBuilder('e')
    .leftJoinAndSelect('e.relacion', 'r')
    .where('e.activo = :activo', { activo: true });

  if (filters.nombre) {
    qb.andWhere('e.nombre ILIKE :nombre', { nombre: `%${filters.nombre}%` });
  }
  if (filters.estado) {
    qb.andWhere('e.estado = :estado', { estado: filters.estado });
  }
  if (filters.fechaDesde && filters.fechaHasta) {
    qb.andWhere('e.created_at BETWEEN :desde AND :hasta', {
      desde: filters.fechaDesde,
      hasta: filters.fechaHasta,
    });
  }

  const [data, total] = await qb
    .orderBy('e.created_at', 'DESC')
    .skip((page - 1) * limit)
    .take(limit)
    .getManyAndCount();

  return { data, total, totalPages: Math.ceil(total / limit) };
}
```

**Agrupación y suma:**
```typescript
const resumen = await this.repo
  .createQueryBuilder('p')
  .select('p.clienteId', 'clienteId')
  .addSelect('COUNT(p.id)', 'totalPedidos')
  .addSelect('SUM(p.total)', 'montoTotal')
  .groupBy('p.clienteId')
  .orderBy('montoTotal', 'DESC')
  .getRawMany();
```

**Query JSONB nativa:**
```typescript
// Buscar dentro de un campo jsonb
const result = await this.repo
  .createQueryBuilder('e')
  .where("e.metadata->>'campo' = :valor", { valor: 'texto' })
  .getMany();
```

**Actualización masiva:**
```typescript
await this.repo
  .createQueryBuilder()
  .update(<Nombre>)
  .set({ estado: 'inactivo', updatedAt: new Date() })
  .where('clienteId = :id AND estado = :estado', { id, estado: 'activo' })
  .execute();
```

---

### `/typeorm migration <nombre>`

```bash
# Generar migration desde cambios en entidades
npx typeorm migration:generate src/migrations/<NombreMigracion> -d src/data-source.ts

# Crear migration en blanco (para escribir manualmente)
npx typeorm migration:create src/migrations/<NombreMigracion>

# Correr migrations pendientes
npx typeorm migration:run -d src/data-source.ts

# Ver cuáles están pendientes
npx typeorm migration:show -d src/data-source.ts

# Revertir última migration
npx typeorm migration:revert -d src/data-source.ts
```

**DataSource (`src/data-source.ts`):**
```typescript
import { DataSource } from 'typeorm';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host:     process.env.DB_HOST     ?? 'localhost',
  port:     parseInt(process.env.DB_PORT ?? '5432'),
  username: process.env.DB_USER     ?? 'postgres',
  password: process.env.DB_PASS     ?? '',
  database: process.env.DB_NAME     ?? 'mi_db',
  entities:   [__dirname + '/**/*.entity{.ts,.js}'],
  migrations: [__dirname + '/migrations/*{.ts,.js}'],
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: false }
    : false,
  logging: process.env.NODE_ENV === 'development',
  synchronize: false,  // NUNCA true en producción
});
```

---

### `/typeorm subscriber <nombre>`

Ejecuta lógica antes/después de operaciones en la entidad:

```typescript
import { EntitySubscriberInterface, EventSubscriber, InsertEvent, UpdateEvent } from 'typeorm';

@EventSubscriber()
export class <Nombre>Subscriber implements EntitySubscriberInterface<<Nombre>> {
  listenTo() { return <Nombre>; }

  beforeInsert(event: InsertEvent<<Nombre>>) {
    // lógica antes de insertar (ej: hashear password, generar código)
    event.entity.codigo = generateCode();
  }

  afterInsert(event: InsertEvent<<Nombre>>) {
    // lógica después de insertar (ej: enviar email, log)
  }

  beforeUpdate(event: UpdateEvent<<Nombre>>) {
    event.entity.updatedAt = new Date();
  }
}
```

Registrar en el módulo NestJS:
```typescript
@Module({
  imports: [TypeOrmModule.forFeature([<Nombre>])],
  providers: [<Nombre>Subscriber],
})
```

---

### `/typeorm index <entidad> <columnas>`

```typescript
// Índice simple
@Index(['nombre'])
export class <Nombre> { ... }

// Índice compuesto
@Index(['clienteId', 'estado'])
export class <Nombre> { ... }

// Índice único
@Index(['email'], { unique: true })
export class Usuario { ... }

// Índice parcial (solo filas activas) — con raw SQL en migration
// No soportado directamente en decoradores; agregar en la migration:
await queryRunner.query(`
  CREATE INDEX CONCURRENTLY idx_<nombre>_activos
  ON <nombre>s(nombre)
  WHERE activo = true
`);
```

---

### Configuración en AppModule

```typescript
TypeOrmModule.forRootAsync({
  imports: [ConfigModule],
  useFactory: (config: ConfigService) => ({
    type: 'postgres',
    host:     config.get('DB_HOST'),
    port:     config.get<number>('DB_PORT'),
    username: config.get('DB_USER'),
    password: config.get('DB_PASS'),
    database: config.get('DB_NAME'),
    entities:    [__dirname + '/**/*.entity{.js,.ts}'],
    migrations:  [__dirname + '/migrations/*{.js,.ts}'],
    synchronize: false,
    ssl: config.get('NODE_ENV') === 'production'
      ? { rejectUnauthorized: false } : false,
    logging: config.get('NODE_ENV') === 'development',
  }),
  inject: [ConfigService],
}),
```

---

### `/typeorm fix` — Problemas comunes

| Error | Causa | Solución |
|---|---|---|
| `EntityMetadataNotFoundError` | Entidad no registrada en `forFeature([])` | Agregar al módulo |
| `QueryFailedError: column does not exist` | Migration no aplicada | `migration:run` |
| Datos decimales como `string` | TypeORM retorna decimales como string | Usar `Number(valor)` o `parseFloat()` |
| N+1 queries | Cargar relaciones dentro de un loop | Usar `leftJoinAndSelect` en una sola query |
| `Cannot read property of undefined` (relación) | Relación no cargada (lazy/eager) | Agregar `relations: { rel: true }` al find |
| Soft delete no funciona | Falta `@DeleteDateColumn` en la entidad | Agregar el decorador |
| Migration autogenerada vacía | Entidad no incluida en DataSource entities | Revisar el glob path |
