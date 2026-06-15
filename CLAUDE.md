# Instrucciones globales — Naidelyn

## Reglas siempre activas

- **Nunca usar Opus** sin consultar primero. Default: Sonnet. Haiku para git ops simples.
- **Nunca comentar** qué hace el código — solo comentar el POR QUÉ si no es obvio.
- **No agregar features extra** — implementar exactamente lo que se pide.
- Todo código, commits, PRs y documentación: **en español**.
- Respuestas cortas y directas. Sin resumir al final lo que ya se hizo.

---

## Auto-activación de skills

Cuando el usuario pida algo relacionado con alguna de estas tecnologías o acciones, **invocar el skill correspondiente ANTES de responder**. No esperar a que el usuario escriba el slash command.

### Frameworks y lenguajes
| Si el usuario menciona... | Invocar |
|---|---|
| Angular / componente / servicio / guard / pipe / módulo / NgModule / standalone | `/angular` |
| Angular Material / mat-table / mat-dialog / mat-form-field / mat-button / CDK | `/material` |
| Tailwind / clases CSS / layout / responsive / dark mode / tema / utilidades CSS | `/tailwind` |
| NestJS / módulo nest / controller nest / DTO / decorador nest / @Injectable / @Module | `/nestjs` |
| .NET / ASP.NET / C# / controller .NET / endpoint .NET / Program.cs / IActionResult | `/dotnet` |
| Next.js / página Next / App Router / Server Component / Client Component / route handler | `/nextjs` |

### Bases de datos y ORM
| Si el usuario menciona... | Invocar |
|---|---|
| EF Core / Entity Framework / DbContext / migration .NET / fluent API / Npgsql | `/efcore` |
| TypeORM / entity TypeORM / repository TypeORM / migration TypeORM / DataSource | `/typeorm` |
| PostgreSQL / postgres / JSONB / pg / query postgres / índice postgres | `/postgres` |
| SQL Server / T-SQL / stored procedure / SSMS / migration SQL Server | `/sqlserver` |

### Cloud y servicios externos
| Si el usuario menciona... | Invocar |
|---|---|
| Supabase / storage supabase / bucket / supabase query / realtime supabase | `/supabase` |
| AWS / S3 / Secrets Manager / SES / DynamoDB / Lambda | `/aws` |
| Firebase / FCM / push notification / firebase-admin / react-native-firebase | `/firebase` |
| Azure AD / MSAL / login Microsoft / Azure Pipelines / AKS | `/azure` |
| JWT / token / refresh token / guard auth / passport / Bearer / API Key auth | `/jwt` |

### Documentación y calidad
| Si el usuario menciona... | Invocar |
|---|---|
| Swagger / OpenAPI / SwaggerOperation / ProducesResponseType / documentar API | `/swagger` |
| test / spec / unit test / e2e / mock / jest / karma / vitest / xUnit | `/testing` |
| eslint / prettier / tslint / lint / formatear código / regla eslint | `/linting` |
| PDF / Excel / QuestPDF / ClosedXML / ExcelJS / pdfmake / reporte / exportar | `/docs` |
| Zustand / store / estado global / persist / slice zustand | `/zustand` |

### Flujo de trabajo y proyecto
| Si el usuario menciona... | Invocar |
|---|---|
| hacer commit / crear commit / mensaje de commit | `/commit` |
| crear PR / pull request / abrir PR | `/pr` |
| ticket Jira / epic / historia / tarea Jira / crear issue | `/jira` |
| notificar / avisar / mandar mensaje Slack / DM / canal Slack | `/notify` |
| abrir proyecto / activar workspace / ir a [alias] / status del repo | `/proyecto` |
| qué cambió / qué hizo [persona] / commits de hoy / repos pendientes | `/scan` |

---

## Estándar de código por tecnología

### .NET / ASP.NET Core
- Swagger **siempre completo** estilo YaloVendo: `[SwaggerOperation]`, `[ProducesResponseType]`, XML comments, `OperationId`
- Respuestas: `SuccessResponse<T>` para 2xx, `ApiErrorResponseDto<TMeta>` RFC 7807 para errores
- Patrón Result: `Result<T>.Ok()`, `Result<T>.NotFound()`, `Result<T>.BadRequest()`
- Logging estructurado con Serilog: `_logger.LogInformation("Mensaje {Campo}", valor)`

### NestJS
- Swagger siempre: `@ApiTags`, `@ApiOperation`, `@ApiResponse`, `@ApiProperty` en DTOs
- DTOs con `class-validator`: `@IsString()`, `@IsNotEmpty()`, `@IsOptional()`
- TypeORM con `Repository<T>`, nunca `any` en tipos

### Angular
- Angular 15+: standalone components siempre (`standalone: true`)
- Inyección con `inject()` — no constructor DI en Angular 14+
- Formularios: siempre `ReactiveFormsModule`, nunca Template-driven para forms complejos
- Nunca `any` en TypeScript

### General
- Nunca `console.log` en producción — usar el logger del framework
- Siempre `async/await` — nunca callbacks
- Tipos explícitos en TypeScript — nunca `any` salvo interop inevitable
