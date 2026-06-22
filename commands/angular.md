---
name: angular
description: Use this skill for Angular components, services, directives, pipes, guards, resolvers, standalone components, inject(), ReactiveFormsModule, FormBuilder, FormGroup, FormControl, Angular Router, ActivatedRoute, HttpClient, Angular signals, ChangeDetectionStrategy, Angular 15+, standalone: true, crear componente Angular, crear servicio Angular, crear guard Angular, formulario Angular.
---

# angular

Asistente para proyectos Angular. Detecta la versión y stack del proyecto activo y genera código siguiendo los patrones reales del proyecto (Angular Material, Tailwind, ESLint/Prettier).

## Uso

```
/angular gen component <nombre>         → genera componente
/angular gen service <nombre>           → genera servicio
/angular gen guard <nombre>             → genera guard (auth/role)
/angular gen pipe <nombre>              → genera pipe
/angular gen module <nombre>            → genera módulo con routing
/angular gen dialog <nombre>            → genera componente de dialog Angular Material
/angular gen table <nombre>             → genera componente con tabla (Material o ag-grid)
/angular gen form <nombre>              → genera componente con formulario reactivo
/angular fix                            → detecta y sugiere fixes para errores comunes
/angular migrate                        → revisa si hay migraciones pendientes de versión
/angular lint                           → corre ESLint/TSLint y muestra errores
```

## Instrucciones de comportamiento

### Paso 1 — Detectar el contexto del proyecto

Leer `~/.claude/projects-registry.md` para identificar el alias activo.
Luego leer `package.json` del proyecto para determinar:
- Versión de Angular (`@angular/core`)
- Stack de UI: Angular Material, Tailwind CSS, Kendo UI, ag-grid
- Testing: Karma/Jasmine vs Vitest
- Linting: ESLint vs TSLint
- Versión de TypeScript

### Paso 2 — Generar según la versión

#### Angular 15+ (standalone components)
Usar `standalone: true`, importar dependencias directamente en el componente.
No usar NgModule salvo que el proyecto ya lo use.

```typescript
// Patrón Angular 15+
@Component({
  selector: 'app-<nombre>',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatButtonModule],
  templateUrl: './<nombre>.component.html',
  styleUrl: './<nombre>.component.scss'
})
export class <Nombre>Component {
  // inject() en lugar de constructor DI cuando Angular 14+
}
```

#### Angular < 15 (NgModule)
Declarar en el módulo correspondiente, usar constructor para DI.

```typescript
@Component({
  selector: 'app-<nombre>',
  templateUrl: './<nombre>.component.html',
  styleUrls: ['./<nombre>.component.scss']
})
export class <Nombre>Component implements OnInit {
  constructor(private service: MiService) {}
}
```

### Generadores específicos

#### `/angular gen component <nombre>`
- Preguntar: ¿standalone? ¿necesita router? ¿qué inputs/outputs tiene?
- Generar: `.ts`, `.html`, `.scss` (vacío si no hay estilos)
- Si el proyecto usa Tailwind: usar clases de Tailwind en el template, no estilos inline
- Si usa Angular Material: importar los módulos de Material necesarios

#### `/angular gen service <nombre>`
- Usar `providedIn: 'root'` por defecto
- Si el servicio hace HTTP, inyectar `HttpClient` y mostrar métodos CRUD base
- Tipar los responses con interfaces, no `any`
- Usar `Observable` con operadores RxJS comunes (`map`, `catchError`, `switchMap`)

#### `/angular gen guard <nombre>`
- Angular 15+: usar functional guards (`CanActivateFn`)
- Angular < 15: usar clase que implementa `CanActivate`
- Si el proyecto usa Azure AD (MSAL): integrar con `MsalGuard`
- Si usa JWT custom: verificar token del localStorage/service

```typescript
// Angular 15+ functional guard
export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  return authService.isAuthenticated() ? true : router.createUrlTree(['/login']);
};
```

#### `/angular gen dialog <nombre>`
- Siempre usar `MatDialog` de Angular Material
- Generar: componente del dialog + interfaz de datos de entrada + valor de retorno
- Incluir botones Cancelar/Confirmar con `MatDialogRef`

#### `/angular gen table <nombre>`
- Si el proyecto tiene **ag-grid** (YaloPOSBackoffice): generar con `AgGridAngular`
- Si no: generar con `MatTable` + `MatPaginator` + `MatSort`
- Incluir columnas como array de strings, datos tipados con interfaz

#### `/angular gen form <nombre>`
- Usar `ReactiveFormsModule` con `FormBuilder`
- Validadores de Angular (`Validators.required`, `Validators.email`, etc.)
- Si el proyecto usa `ngx-mask`: incluir máscara en los campos
- Template con `mat-form-field` y `matInput` si hay Angular Material

#### `/angular fix`
Revisar errores comunes según versión:
- **NG0100** (ExpressionChangedAfterItHasBeenCheckedError): buscar bindings problemáticos
- **NG0301** (No directive found): módulo no importado
- **NG8001** (Unknown element): componente no declarado o importado
- Imports circulares
- Standalone + NgModule mezclados

#### `/angular lint`
Correr `ng lint` o `eslint src/` y mostrar los errores agrupados por archivo.
Ofrecer fix automático para los que sean auto-fixables (`--fix`).

### Patrones del stack real

**Proyectos con Tailwind + Angular Material:**
- Layout con clases Tailwind (`flex`, `grid`, `p-4`, etc.)
- Componentes UI con Angular Material (`mat-button`, `mat-card`, `mat-table`)
- No mezclar estilos inline con Tailwind

**Proyectos con Azure AD (MSAL):**
- Configuración de `MsalModule` en `app.config.ts`
- Interceptor `MsalInterceptor` para agregar tokens
- Guard con `MsalGuard`

**Proyectos con SignalR:**
- Usar `@microsoft/signalr` directamente, no wrapeado en servicio
- Reconexión automática con `withAutomaticReconnect()`

### Versiones de Angular en el portfolio

| Alias | Versión Angular |
|---|---|
| yalo bo (YaloPOSBackoffice) | 15 (Ionic) |
| yalo agendo | 21 |
| yalo consumer | 19 |
| yalo console | 19 |
| yalo monitor | 16 (Ionic) |
| yalo cap (YALO-APP-CAP) | 15 (Ionic) |
| bodega bo | 20 |
| cpa fe | 10 |
| corinsa bi fe | 7 |
| doctor fe | 13 |
| nai inhands bo | 21 (con SSR) |
| ult bo / ult ecom | 16 (NX monorepo) |
