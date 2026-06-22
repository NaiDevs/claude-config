---
name: doctor
description: Use this skill to validate project setup, check dependencies, verify environment variables, diagnose configuration problems, check if the project can run, missing packages, missing env vars, broken configuration, validate workspace, diagnosticar proyecto, validar configuración, verificar dependencias.
---

# /doctor

Diagnóstico del proyecto activo. Verifica que todo esté en orden para trabajar o deployar.

## Cuándo usar

- Al abrir un proyecto por primera vez o después de mucho tiempo sin tocarlo
- Cuando el proyecto no levanta y no está claro por qué
- Antes de un deploy para verificar configuración
- Para onboarding de un nuevo equipo o dispositivo

## Loop de trabajo

```
1. Verificar dependencias instaladas
   → package.json existe
   → node_modules existe (o .yarn/cache si usa Yarn)
   → Si no: npm install / yarn install

2. Verificar variables de entorno
   → .env existe (o .env.local, etc.)
   → Variables críticas no vacías (DB_HOST, JWT_SECRET, etc.)
   → Sin credenciales hardcodeadas en código

3. Verificar base de datos
   → Connection string válida
   → DB accesible desde el entorno actual
   → Migrations aplicadas (migration:show)

4. Verificar build
   → TypeScript compila sin errores
   → Sin imports rotos

5. Verificar servicios externos
   → Firebase: credenciales configuradas
   → Servicios de email: API key presente
   → Storage: credenciales presentes

6. Reportar
   → [OK] lo que funciona
   → [WARN] lo que falta pero no bloquea
   → [ERROR] lo que impide que el proyecto funcione
```

## Checks por tipo de proyecto

**NestJS:**
```bash
# Verificar que levanta
npm run start:dev

# Verificar migrations pendientes
npx typeorm migration:show -d src/data-source.ts

# Verificar build
npm run build

# Verificar variables de entorno mínimas
cat .env | grep -E "^(DB_HOST|DB_PORT|JWT_SECRET|PORT)"
```

**Angular:**
```bash
# Verificar build
ng build --configuration=production

# Verificar que levanta
ng serve

# Verificar lint
ng lint
```

## Checklist rápido

```
[ ] node_modules instalados
[ ] .env configurado con todas las variables requeridas
[ ] DB accesible
[ ] Migrations aplicadas
[ ] npm run build / ng build sin errores
[ ] No hay console.log con datos sensibles
[ ] No hay secretos en el código fuente
```
