---
name: api-contract
description: Use this skill when changing or reviewing API endpoints, request DTOs, response DTOs, Swagger/OpenAPI documentation, Angular services, frontend-backend contracts, pagination response shapes, filters, sorting, backward compatibility, cambiar endpoint, cambiar DTO, compatibilidad frontend, romper contrato, actualizar servicio Angular.
---

# /api-contract

Workflow para cambiar o revisar endpoints manteniendo compatibilidad frontend-backend. Evita romper contratos sin querer.

## Cuándo usar

- Agregar, modificar o eliminar un endpoint
- Cambiar el shape del request DTO o response DTO
- Actualizar la documentación Swagger
- Crear o actualizar el servicio Angular que consume el endpoint
- Revisar si un cambio backend rompe algo en el frontend
- Agregar paginación, filtros o sorting a un endpoint existente
- Cambiar tipo de campo (ej: `number` → `string`, `Date` → `ISO string`)

## Triggers

`DTO`, `endpoint`, `request`, `response`, `Swagger`, `OpenAPI`, `servicio Angular`, `HttpClient`, `paginación`, `backward compatibility`, `romper contrato`, `cambio de API`, `filtros`, `sorting`

## Loop de trabajo

```
1. Revisar el endpoint actual
   → Leer el controller y el service
   → Leer el DTO de request y response existente
   → Leer la documentación Swagger actual

2. Identificar consumidores frontend
   → Buscar el servicio Angular que llama el endpoint
   → Revisar las interfaces TypeScript usadas en el componente
   → Identificar cómo se mapean los datos en el template

3. Evaluar impacto del cambio
   → ¿Cambia la estructura del response? → breaking change
   → ¿Agrega campos opcionales? → additive change (seguro)
   → ¿Elimina o renombra campos? → breaking change
   → ¿Cambia tipos? → verificar compatibilidad en frontend

4. Estrategia de cambio
   → Additive: agregar campo opcional, mantener los existentes
   → Breaking: versionar el endpoint (/v2/) o coordinar con frontend
   → Deprecar campo antes de eliminar (añadir en Swagger)

5. Implementar cambio
   → Backend: DTO + Controller + Service + Swagger
   → Frontend: interfaz + servicio + componentes
   → Hacerlo en el mismo PR si es posible

6. Validar
   → Swagger correcto y completo
   → Servicio Angular tipado correctamente
   → Componentes usan los nuevos campos sin errores TypeScript
```

## Reglas

- **Nunca eliminar un campo de response sin verificar todos los consumidores frontend**
- Campos nuevos en response: siempre opcionales con `?` en la interfaz Angular
- Nunca cambiar el tipo de un campo existente sin coordinar frontend y backend al mismo tiempo
- Todos los endpoints deben tener documentación Swagger completa
- Las respuestas paginadas siempre con el mismo shape: `{ data, total, page, limit, totalPages }`
- Los filtros y sorting se reciben como query params, no como body
- Ante duda: agregar el campo nuevo Y mantener el viejo (additive), no reemplazar

## Shape estándar de responses

**Response con paginación:**
```typescript
// Backend DTO
export class PaginatedResponseDto<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// Frontend interface
export interface Paginated<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
```

**Request con filtros:**
```typescript
// Backend DTO
export class FiltroFacturasDto {
  @IsOptional() @IsString()
  search?: string;

  @IsOptional() @IsEnum(EstadoFactura)
  estado?: EstadoFactura;

  @IsOptional() @Type(() => Date) @IsDate()
  fechaDesde?: Date;

  @IsOptional() @Type(() => Date) @IsDate()
  fechaHasta?: Date;

  @IsOptional() @Type(() => Number) @IsInt() @Min(1)
  page?: number = 1;

  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100)
  limit?: number = 25;
}
```

**Swagger completo:**
```typescript
@ApiTags('facturas')
@ApiOperation({
  summary: 'Listar facturas',
  description: 'Retorna facturas paginadas con filtros opcionales',
})
@ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
@ApiQuery({ name: 'limit', required: false, type: Number, example: 25 })
@ApiResponse({ status: 200, description: 'Lista paginada', type: PaginatedResponseDto })
@ApiResponse({ status: 401, description: 'No autenticado' })
@Get()
findAll(@Query() filtros: FiltroFacturasDto) { ... }
```

**Servicio Angular:**
```typescript
// Siempre tipar el response con la interfaz — nunca 'any'
findAll(filtros: FiltroFacturas): Observable<Paginated<Factura>> {
  const params = new HttpParams({ fromObject: { ...filtros } });
  return this.http.get<Paginated<Factura>>(`${this.base}/facturas`, { params });
}
```

## Ejemplos

**Agregar campo opcional (safe):**
```typescript
// Backend: agregar campo nuevo con nullable
export class FacturaResponseDto {
  id: number;
  total: number;
  // Nuevo campo — opcional, no rompe frontend actual
  codigoExterno?: string;
}
// Frontend: agregar en interfaz como opcional
export interface Factura {
  id: number;
  total: number;
  codigoExterno?: string; // nuevo
}
```

**Cambiar tipo de campo (breaking — coordinar):**
```typescript
// Antes: clienteId: number
// Después: clienteId: string (UUID)
// → En el mismo PR: cambiar backend + interfaz Angular + todos los lugares que usen el campo
```
