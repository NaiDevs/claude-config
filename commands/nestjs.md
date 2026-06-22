---
name: nestjs
description: Use this skill for NestJS modules, controllers, services, DTOs, guards, interceptors, pipes, decorators, @Injectable, @Module, @Controller, @Get, @Post, @Put, @Patch, @Delete, NestJS API, class-validator, class-transformer, ConfigService, NestJS project structure, crear módulo nest, crear servicio nest, crear controller nest, crear DTO, endpoint NestJS.
---

# nestjs

Asistente para proyectos NestJS. Genera código siguiendo los patrones reales del stack: NestJS 11, TypeORM, PostgreSQL, class-validator, JWT/API Key auth, SWC.

## Uso

```
/nestjs gen module <nombre>         → genera módulo completo (module + controller + service + dto)
/nestjs gen endpoint <método> <ruta> → agrega un endpoint al controller activo
/nestjs gen dto <nombre>            → genera DTO con class-validator
/nestjs gen entity <nombre>         → genera entidad TypeORM
/nestjs gen guard <tipo>            → genera guard (jwt / api-key / role)
/nestjs gen middleware <nombre>     → genera middleware
/nestjs gen migration               → genera migration TypeORM con los cambios pendientes
/nestjs gen seed <nombre>           → genera seeder de datos
/nestjs fix                         → detecta problemas comunes (DI, imports, tipos)
/nestjs test <nombre>               → genera unit test Jest para un servicio o controller
```

## Instrucciones de comportamiento

### Paso 1 — Verificar el proyecto activo

Leer `package.json` para confirmar versión NestJS y dependencias disponibles.
El stack base de los proyectos es:
- `@nestjs/core` 11.x, `@nestjs/common` 11.x
- `typeorm` 0.3.x + `pg` (PostgreSQL)
- `class-validator` + `class-transformer`
- `@nestjs/jwt` + `passport-jwt` (auth)
- `@swc/core` (compilación rápida)
- `jest` + `ts-jest` (testing)
- `@nestjs/swagger` (documentación)

### Generadores

#### `/nestjs gen module <nombre>`

Generar la estructura completa de un módulo en `src/<nombre>/`:

```
src/
  <nombre>/
    dto/
      create-<nombre>.dto.ts
      update-<nombre>.dto.ts
    entities/
      <nombre>.entity.ts
    <nombre>.controller.ts
    <nombre>.module.ts
    <nombre>.service.ts
```

**Controller** — con decoradores Swagger incluidos:
```typescript
@ApiTags('<nombre>')
@Controller('<nombre>')
export class <Nombre>Controller {
  constructor(private readonly <nombre>Service: <Nombre>Service) {}

  @Post()
  @ApiOperation({ summary: 'Crear <nombre>' })
  create(@Body() dto: Create<Nombre>Dto) {
    return this.<nombre>Service.create(dto);
  }

  @Get()
  findAll() { return this.<nombre>Service.findAll(); }

  @Get(':id')
  findOne(@Param('id') id: string) { return this.<nombre>Service.findOne(+id); }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: Update<Nombre>Dto) {
    return this.<nombre>Service.update(+id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) { return this.<nombre>Service.remove(+id); }
}
```

**Service** — con TypeORM repository:
```typescript
@Injectable()
export class <Nombre>Service {
  constructor(
    @InjectRepository(<Nombre>)
    private readonly repo: Repository<<Nombre>>,
  ) {}

  create(dto: Create<Nombre>Dto) {
    const entity = this.repo.create(dto);
    return this.repo.save(entity);
  }

  findAll() { return this.repo.find(); }
  findOne(id: number) { return this.repo.findOneBy({ id }); }

  async update(id: number, dto: Update<Nombre>Dto) {
    await this.repo.update(id, dto);
    return this.findOne(id);
  }

  remove(id: number) { return this.repo.delete(id); }
}
```

#### `/nestjs gen dto <nombre>`

```typescript
import { IsString, IsNotEmpty, IsOptional, IsEmail, IsNumber } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class Create<Nombre>Dto {
  @ApiProperty({ description: 'Campo requerido' })
  @IsString()
  @IsNotEmpty()
  campo: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  campoOpcional?: string;
}

export class Update<Nombre>Dto extends PartialType(Create<Nombre>Dto) {}
```

#### `/nestjs gen entity <nombre>`

```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('<nombre>s')
export class <Nombre> {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  nombre: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

Preguntar qué columnas necesita antes de generar. Agregar relaciones (`@ManyToOne`, `@OneToMany`) si se indican.

#### `/nestjs gen guard <tipo>`

**JWT Guard** (basado en el patrón de los proyectos):
```typescript
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
```

**API Key Guard**:
```typescript
@Injectable()
export class ApiKeyGuard implements CanActivate {
  constructor(private config: ConfigService) {}

  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest();
    const key = req.headers['x-api-key'];
    return key === this.config.get('API_KEY');
  }
}
```

**Role Guard**:
```typescript
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const roles = this.reflector.get<string[]>('roles', ctx.getHandler());
    if (!roles) return true;
    const { user } = ctx.switchToHttp().getRequest();
    return roles.includes(user.role);
  }
}
```

#### `/nestjs gen migration`

Correr:
```bash
npx typeorm migration:generate src/migrations/<NombreMigracion> -d src/data-source.ts
```

Mostrar el contenido de la migration generada y preguntar si ejecutarla con `migration:run`.

#### `/nestjs test <nombre>`

Generar unit test para un servicio con mocks de TypeORM:
```typescript
describe('<Nombre>Service', () => {
  let service: <Nombre>Service;
  let repo: jest.Mocked<Repository<<Nombre>>>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        <Nombre>Service,
        {
          provide: getRepositoryToken(<Nombre>),
          useValue: {
            find: jest.fn(),
            findOneBy: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
            update: jest.fn(),
            delete: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(<Nombre>Service);
    repo = module.get(getRepositoryToken(<Nombre>));
  });

  it('should be defined', () => expect(service).toBeDefined());
  // ...más tests
});
```

### Patrones del stack real

**Autenticación en los proyectos:**
- La Bodega: JWT (`passport-jwt`) + Header API Key (`passport-headerapikey`)
- YALO Admin: JWT + Supabase

**Base de datos:**
- Siempre PostgreSQL con TypeORM 0.3.x
- Data source en `src/data-source.ts` o `src/app.module.ts`
- Migrations en `src/migrations/`

**Estructura de módulos en La Bodega APIs:**
```
src/
  modules/
    <feature>/
      dto/
      entities/
      <feature>.controller.ts
      <feature>.service.ts
      <feature>.module.ts
  common/
    guards/
    decorators/
    filters/
  main.ts
  app.module.ts
```

**Servicios externos ya integrados:**
- Slack: `@slack/web-api` (YALO Admin)
- SendGrid: `@sendgrid/mail` (La Bodega)
- AWS Secrets Manager: para variables sensibles
- Firebase Admin: para push notifications
- Supabase: storage y auth
