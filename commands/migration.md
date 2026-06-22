---
name: migration
description: Use this skill for database migrations, TypeORM migrations, EF Core migrations, schema changes, adding columns, renaming columns, changing column types, data migrations, migration scripts, migración de base de datos, agregar columna, cambiar tipo, migration TypeORM, rollback de migración.
---

# /migration

Workflow para crear, revisar y ejecutar migrations de base de datos de forma segura.

## Cuándo usar

- Agregar una columna nueva a una tabla
- Cambiar el tipo de una columna
- Agregar una tabla nueva o relación
- Backfill de datos (llenar columna nueva con datos existentes)
- Eliminar columna o tabla (con precaución)
- Revisar migrations pendientes antes de un deploy

## Reglas de seguridad

- **NUNCA `synchronize: true` en producción** — siempre migrations manuales
- Probar la migration en staging ANTES de producción
- Columnas nuevas: siempre `nullable: true` o con `DEFAULT` para no romper datos existentes
- Eliminar columna: primero deprecar (dejar de usar en código), luego eliminar en otro deploy
- Cambiar tipo de columna: puede perder datos — siempre con backup previo
- Siempre incluir el método `down()` para poder revertir

## Loop de trabajo

```
1. Identificar el cambio de schema
   → ¿Qué entidad cambia?
   → ¿Qué impacto tiene en datos existentes?
   → ¿Es backwards-compatible? (código viejo + schema nuevo = funciona?)

2. Generar o escribir la migration
   → TypeORM: migration:generate si vienen de cambios en entidades
   → Manual si es backfill o cambio de tipo
   → Incluir siempre método down()

3. Revisar la migration generada
   → Verificar que el SQL es el esperado
   → Verificar que el rollback restaura el estado anterior

4. Probar en staging
   → migration:run en staging
   → Verificar que la aplicación funciona
   → Opcional: migration:revert y migration:run de nuevo

5. Incluir en el PR
   → La migration va en el mismo PR que el código que la requiere
   → O en un PR separado que se mergea ANTES

6. Deploy en producción
   → migration:run ANTES de deployar el nuevo código
   → Verificar aplicación después del deploy
```

## TypeORM — comandos

```bash
# Generar migration desde cambios en entidades
npx typeorm migration:generate src/migrations/NombreMigracion -d src/data-source.ts

# Crear migration en blanco (para escribir manualmente)
npx typeorm migration:create src/migrations/NombreMigracion

# Ver migrations pendientes
npx typeorm migration:show -d src/data-source.ts

# Ejecutar migrations pendientes
npx typeorm migration:run -d src/data-source.ts

# Revertir la última migration
npx typeorm migration:revert -d src/data-source.ts
```

## Patrones comunes

**Agregar columna nullable (seguro):**
```typescript
export class AddCodigoExternoToFacturas implements MigrationInterface {
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn('facturas', new TableColumn({
      name: 'codigo_externo',
      type: 'varchar',
      length: '50',
      isNullable: true,  // ← siempre nullable en migraciones additive
    }));
  }
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('facturas', 'codigo_externo');
  }
}
```

**Backfill de datos:**
```typescript
async up(queryRunner: QueryRunner): Promise<void> {
  // Primero agregar la columna
  await queryRunner.addColumn('usuarios', new TableColumn({
    name: 'nombre_completo',
    type: 'varchar',
    isNullable: true,
  }));
  // Luego backfill
  await queryRunner.query(`
    UPDATE usuarios
    SET nombre_completo = CONCAT(nombre, ' ', apellido)
    WHERE nombre_completo IS NULL
  `);
  // Opcional: hacer NOT NULL después del backfill
  await queryRunner.changeColumn('usuarios', 'nombre_completo', new TableColumn({
    name: 'nombre_completo',
    type: 'varchar',
    isNullable: false,
  }));
}
```

**Agregar índice:**
```typescript
async up(queryRunner: QueryRunner): Promise<void> {
  await queryRunner.createIndex('facturas', new TableIndex({
    name: 'IDX_facturas_cliente_estado',
    columnNames: ['cliente_id', 'estado'],
  }));
}
async down(queryRunner: QueryRunner): Promise<void> {
  await queryRunner.dropIndex('facturas', 'IDX_facturas_cliente_estado');
}
```
