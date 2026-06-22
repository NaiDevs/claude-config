---
name: security
description: Use this skill for security audits, SQL injection, authentication bypass, authorization flaws, exposed secrets, hardcoded credentials, JWT vulnerabilities, insecure endpoints, OWASP, XSS, CORS issues, access control, sensitive data exposure, auditoria de seguridad, secretos expuestos, endpoint sin proteger.
---

# /security

Auditoría de seguridad para código backend (NestJS) y frontend (Angular). Detecta problemas OWASP Top 10 y patrones inseguros comunes del stack.

## Cuándo usar

- Audit de seguridad antes de un deploy a producción
- Revisar un endpoint crítico (pagos, auth, datos sensibles)
- Detectar secretos expuestos en el código
- Revisar configuración de CORS, JWT y guards
- Verificar que los permisos están bien implementados

## Loop de trabajo

```
1. Identificar superficie de ataque
   → Endpoints públicos (sin guard)
   → Endpoints que reciben input del usuario
   → Endpoints que acceden a datos sensibles

2. Revisar autenticación
   → JWT: algoritmo (debe ser RS256 o HS256 con secret fuerte), expiración, refresh
   → API Key: no en URL params, solo en headers
   → Sin bypass por endpoint no protegido

3. Revisar autorización
   → Todos los endpoints con datos tienen guard + permiso
   → No confiar en IDs del cliente sin verificar ownership
   → Sin "admin=true" en body que se procese sin verificar

4. Revisar input
   → DTOs con class-validator en todos los endpoints
   → Sin SQL concatenado (usar QueryBuilder con parámetros)
   → Sin eval() ni ejecución de código del usuario

5. Revisar datos sensibles
   → Sin passwords en logs ni en responses
   → Sin tokens en URLs
   → Datos de tarjetas: nunca almacenar

6. Revisar configuración
   → CORS restrictivo (no '*' en producción)
   → Rate limiting en endpoints de auth
   → Variables de entorno para todos los secretos
```

## Reglas

- NUNCA imprimir secretos, passwords o tokens en logs
- NUNCA commitear `.env`, `mcp.env` o archivos con credenciales
- NUNCA usar `synchronize: true` en TypeORM en producción
- NUNCA confiar en roles/permisos que vienen del body del request
- CORS `*` es aceptable solo en desarrollo local

## Vulnerabilidades comunes en el stack

**SQL Injection (TypeORM):**
```typescript
// INSEGURO ❌
repo.query(`SELECT * FROM usuarios WHERE email = '${email}'`);

// SEGURO ✓
repo.query('SELECT * FROM usuarios WHERE email = $1', [email]);
// O mejor:
repo.findOneBy({ email });
repo.createQueryBuilder().where('email = :email', { email }).getOne();
```

**Exposición de datos sensibles:**
```typescript
// INSEGURO ❌ — retorna el password hasheado
@Get(':id')
findOne(@Param('id') id: string) {
  return this.repo.findOneBy({ id: +id });
}

// SEGURO ✓ — excluir campos sensibles del response
@Get(':id')
async findOne(@Param('id') id: string) {
  const user = await this.repo.findOneBy({ id: +id });
  const { password, ...result } = user;
  return result;
}
// O usar @Exclude() en la entidad + ClassSerializerInterceptor
```

**IDOR (Insecure Direct Object Reference):**
```typescript
// INSEGURO ❌ — cualquier usuario puede ver facturas de otro
@Get('facturas/:id')
@UseGuards(JwtAuthGuard)
findOne(@Param('id') id: string) {
  return this.facturasService.findOne(+id);
}

// SEGURO ✓ — verificar que la factura pertenece al usuario
@Get('facturas/:id')
@UseGuards(JwtAuthGuard)
findOne(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
  return this.facturasService.findOneForUser(+id, user.sub);
}
// En el service: WHERE id = :id AND usuario_id = :userId
```

**Secretos en código:**
```typescript
// INSEGURO ❌
const jwtSecret = 'mi-secreto-hardcodeado';

// SEGURO ✓
const jwtSecret = this.configService.get<string>('JWT_SECRET');
if (!jwtSecret) throw new Error('JWT_SECRET no configurado');
```

**CORS en producción:**
```typescript
// INSEGURO ❌ (para producción)
app.enableCors(); // equivale a origin: '*'

// SEGURO ✓
app.enableCors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? [],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  credentials: true,
});
```

## Checklist pre-deploy

```
[ ] Todos los endpoints sensibles tienen JwtAuthGuard + PermissionsGuard
[ ] Sin console.log con datos de usuario
[ ] Sin secretos hardcodeados en el código
[ ] JWT_SECRET fuerte y en variable de entorno
[ ] CORS configurado con origenes específicos
[ ] Rate limiting en /auth/login y /auth/register
[ ] synchronize: false en TypeORM
[ ] Passwords hasheados (bcrypt, nunca MD5/SHA1 solo)
[ ] Sin SQL concatenado
[ ] DTOs con validación en todos los POST/PUT/PATCH
[ ] Headers de seguridad (helmet)
```
