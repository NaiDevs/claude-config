---
name: permissions
description: Use this skill for authentication, authorization, roles, permissions, modules, actions, guards, decorators, JWT, API keys, auth/permissions endpoints, menu visibility, frontend permissions, Angular guards, backend access control, permisos, roles, acceso denegado, 403, guard, módulo, acción, visibilidad de menú.
---

# /permissions

Workflow para implementar o depurar el sistema de permisos dinámicos. Cubre backend (guards, decoradores) y frontend (visibilidad de menú, guards Angular).

## Cuándo usar

- Implementar control de acceso a un endpoint o feature nuevo
- Debuggear un 403 inesperado
- Agregar un módulo/acción nuevo al sistema de permisos
- Revisar por qué un menú o botón no aparece en el frontend
- Implementar un guard en Angular para una ruta protegida
- Agregar un rol nuevo o modificar permisos existentes

## Triggers

`permissions`, `permisos`, `roles`, `módulo`, `acción`, `guard`, `401`, `403`, `acceso denegado`, `auth/permissions`, `JWT`, `API key`, `visibilidad`, `menú`, `CanActivate`, `@Roles`, `@UseGuards`, `HasPermission`

## Arquitectura del sistema de permisos

```
Actor (usuario con JWT)
  → tiene Roles
    → cada Rol tiene Permisos
      → cada Permiso tiene Módulo + Acción

Backend:
  JwtAuthGuard → extrae usuario del token
  PermissionsGuard → verifica que usuario tiene el módulo:acción requerido
  @RequirePermission('modulo', 'accion') → decorador en el endpoint

Frontend:
  GET /auth/permissions → retorna lista de permisos del usuario
  PermissionsService → guarda y consulta permisos
  *hasPermission directive / hasPermission pipe → visibilidad de elementos
  AuthGuard / PermissionGuard → protege rutas
```

## Loop de trabajo

```
1. Identificar Actor, Recurso y Acción
   → ¿Quién hace la acción? (rol del usuario)
   → ¿Sobre qué recurso? (módulo)
   → ¿Qué acción? (leer, crear, editar, eliminar, aprobar...)

2. Backend — proteger el endpoint
   → Agregar @UseGuards(JwtAuthGuard, PermissionsGuard)
   → Agregar @RequirePermission('modulo', 'accion')
   → Verificar que el módulo/acción existen en la DB

3. Backend — registrar el permiso si es nuevo
   → Insertar en tabla modules o permissions si corresponde
   → Asignar al rol correspondiente

4. Frontend — controlar visibilidad
   → Verificar que GET /auth/permissions retorna el nuevo permiso
   → Usar *hasPermission="'modulo:accion'" en el template
   → O verificar en el componente con permissionsService.has('modulo', 'accion')

5. Frontend — guard de ruta (si aplica)
   → Configurar PermissionGuard en el routing con el permiso requerido

6. Probar los dos caminos
   → Usuario CON el permiso: debe pasar
   → Usuario SIN el permiso: debe recibir 403 (backend) o no ver el elemento (frontend)
```

## Reglas

- Nunca confiar solo en visibilidad frontend — el backend SIEMPRE valida permisos
- El guard de JWT va antes que el guard de permisos
- Cuando se agrega un módulo/acción nuevo: crear la migration o seed para registrarlo
- El endpoint `GET /auth/permissions` siempre retorna los permisos del usuario autenticado — no cachear indefinidamente
- En frontend: usar el permiso más específico disponible, no "es admin"
- Para botones y elementos de UI: `*hasPermission` directive o pipe, no `*ngIf="user.role === 'admin'"`

## Patrones de implementación

**Backend — Guard:**
```typescript
// permissions.guard.ts
@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<{module: string; action: string}>(
      PERMISSION_KEY,
      [ctx.getHandler(), ctx.getClass()],
    );
    if (!required) return true; // no requiere permiso específico

    const { user } = ctx.switchToHttp().getRequest();
    return user?.permissions?.some(
      (p) => p.module === required.module && p.action === required.action,
    ) ?? false;
  }
}

// Decorador
export const RequirePermission = (module: string, action: string) =>
  SetMetadata(PERMISSION_KEY, { module, action });
```

**Backend — Endpoint protegido:**
```typescript
@Get()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@RequirePermission('facturas', 'leer')
@ApiOperation({ summary: 'Listar facturas' })
findAll() { ... }
```

**Backend — Endpoint de permisos:**
```typescript
@Get('permissions')
@UseGuards(JwtAuthGuard)
async getMyPermissions(@CurrentUser() user: JwtPayload) {
  return this.authService.getUserPermissions(user.sub);
}
// Response: [{ module: 'facturas', action: 'leer' }, ...]
```

**Frontend — Servicio:**
```typescript
@Injectable({ providedIn: 'root' })
export class PermissionsService {
  private perms = signal<string[]>([]);

  loadPermissions(): Observable<void> {
    return this.http.get<Permission[]>('/api/auth/permissions').pipe(
      tap(perms => this.perms.set(perms.map(p => `${p.module}:${p.action}`))),
      map(() => void 0),
    );
  }

  has(module: string, action: string): boolean {
    return this.perms().includes(`${module}:${action}`);
  }
}
```

**Frontend — Directive:**
```typescript
@Directive({ selector: '[hasPermission]', standalone: true })
export class HasPermissionDirective {
  constructor(
    private tpl: TemplateRef<any>,
    private vcr: ViewContainerRef,
    private perms: PermissionsService,
  ) {}

  @Input() set hasPermission(perm: string) {
    const [module, action] = perm.split(':');
    if (this.perms.has(module, action)) {
      this.vcr.createEmbeddedView(this.tpl);
    } else {
      this.vcr.clear();
    }
  }
}

// Uso en template:
// <button *hasPermission="'facturas:crear'">Nueva factura</button>
```

**Frontend — Guard de ruta:**
```typescript
export const permissionGuard = (module: string, action: string): CanActivateFn =>
  () => {
    const perms = inject(PermissionsService);
    const router = inject(Router);
    return perms.has(module, action) || router.createUrlTree(['/403']);
  };

// En routing:
{
  path: 'facturas',
  canActivate: [permissionGuard('facturas', 'leer')],
  component: FacturasComponent,
}
```

## Debugging 403

```
1. Verificar que el token JWT es válido (no expirado, correcto)
2. Verificar que el usuario tiene el rol correcto
3. Verificar que el rol tiene el permiso módulo:acción requerido en DB
4. Verificar que el guard está bien configurado en el endpoint
5. Verificar que el decorador @RequirePermission tiene el módulo/acción correcto
6. Si todo está en DB: revisar que el servicio de permisos los carga correctamente
```
