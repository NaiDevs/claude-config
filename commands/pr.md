---
description: Genera Pull Requests descriptivos en español — título, cambios realizados, tabla de archivos y checklist de pruebas
---

# pr

Genera un Pull Request descriptivo en español analizando todos los commits y cambios de la rama actual vs la rama base. Muestra qué se hizo, qué archivos se tocaron y un checklist de pruebas.

## Uso

```
/pr                  → genera el PR contra la rama base detectada (main/master/develop)
/pr --base develop   → especifica la rama base manualmente
/pr --dry            → muestra el borrador sin crear el PR
/pr --draft          → crea el PR como borrador (draft)
```

## Instrucciones

### Paso 1 — Entender el contexto de la rama

Correr en paralelo:
- `git branch --show-current` — nombre de la rama actual
- `git log main...HEAD --oneline` (o develop si no existe main) — commits de esta rama
- `git diff main...HEAD --stat` — resumen de archivos cambiados
- `git diff main...HEAD` — diff completo (para análisis)
- `gh pr list --head <rama-actual>` — verificar si ya existe un PR abierto

Si ya existe un PR abierto: informar y preguntar si se quiere actualizar el body o crear uno nuevo.

### Paso 2 — Analizar el conjunto de cambios

Entender:
- **El objetivo principal** de la rama (qué feature, fix o refactor implementa)
- **Los módulos o áreas** afectadas
- **El impacto** potencial (¿toca endpoints? ¿cambia UI? ¿modifica BD? ¿afecta performance?)
- **Los archivos clave** vs los archivos de soporte (config, lock files, etc.)

### Paso 3 — Generar el PR

**Título**: máximo 70 caracteres, descriptivo, en español, imperativo.
Ejemplos:
- `Agrega sección La Bodega TV con lives, reels y blog`
- `Corrige freeze del navegador por loop infinito en AuthContext`
- `Refactoriza HomeDynamicSections a fetching en paralelo`

**Body** con esta estructura:

```markdown
## ¿Qué hace este PR?
<1-3 oraciones describiendo el objetivo principal>

## Cambios realizados
- <cambio 1>
- <cambio 2>
- <cambio 3>

## Archivos modificados
| Archivo | Cambio |
|---------|--------|
| `ruta/al/archivo.ts` | descripción del cambio |
| `ruta/al/archivo.html` | descripción del cambio |

## Checklist de pruebas
- [ ] <caso de prueba 1>
- [ ] <caso de prueba 2>
- [ ] <caso edge case importante>

## Notas adicionales
<solo si hay algo que el reviewer deba saber: migraciones, variables de entorno, dependencias nuevas, etc. Omitir si no aplica>
```

**Reglas del body:**
- Todo en español
- La sección "Archivos modificados" excluye: `package-lock.json`, `*.lock`, `.gitignore`, archivos de config menores — salvo que el cambio sea sobre ellos
- Si hay más de 15 archivos, agrupar por módulo en vez de listar uno a uno
- El checklist de pruebas debe ser específico al cambio, no genérico ("verificar que compila" no vale)
- No mencionar a Claude ni agregar co-autores

### Paso 4 — Mostrar borrador y confirmar

Mostrar el título y body propuesto. Preguntar:
```
¿Creamos el PR con este contenido? (s/editar/n)
```
- `s` → ejecutar `gh pr create`
- `editar` → mostrar para que el usuario modifique
- `n` → cancelar

Si `--dry` fue pasado: solo mostrar el borrador, no preguntar.

### Paso 5 — Crear el PR

```
gh pr create --title "<título>" --body "<body>" [--draft si se pasó --draft]
```

Mostrar la URL del PR creado.

### Paso 6 — Guardar en memoria engram

Después de crear el PR exitosamente, agregar una entrada al archivo de memoria:
`C:\Users\naide\.claude\projects\C--Users-naide\memory\changes-log.md`

Formato de la entrada a agregar al final del archivo:
```
- YYYY-MM-DD | <alias del proyecto activo> | pr | <título del PR>
```

Ejemplo:
```
- 2026-06-14 | bodega ecommerce | pr | Implementa sección La Bodega TV con lives y blog
```

Si no se conoce el alias del proyecto activo, usar el nombre de la carpeta del repo.
Si el archivo supera 100 entradas, eliminar las más antiguas hasta quedar en 100.

### Detectar la rama base

Orden de preferencia:
1. La especificada con `--base`
2. `develop` si existe en el remoto
3. `main` si existe
4. `master` como fallback

## Ejemplos de PRs bien formados

### Ejemplo 1 — Feature
```
Título: Implementa sección La Bodega TV con lives, blog y búsqueda visual

## ¿Qué hace este PR?
Agrega la sección completa de La Bodega TV al e-commerce, incluyendo lives en tiempo real, reels, blog con scroll infinito y mejoras en la búsqueda visual por cámara.

## Cambios realizados
- Nuevo componente TVHomeSection con categorías y productos
- Integración de lives con CardLive y LivesSection
- Blog con paginación infinita y filtro por categoría
- Búsqueda visual por cámara ahora es asíncrona y con paginación
- Corrección de freeze por loop infinito en cambio de cuenta

## Archivos modificados
| Archivo | Cambio |
|---------|--------|
| `components/tv/TVHomeSection.tsx` | componente nuevo con fetch de datos |
| `components/tv/CardLive.tsx` | card de live con CTA móvil |
| `components/blog/BlogSection.tsx` | scroll infinito y filtro de categorías |
| `contexts/auth.context.tsx` | corrige dependencia faltante en useEffect |
| `components/search/CameraSearchButton.tsx` | función asíncrona y paginación |

## Checklist de pruebas
- [ ] La sección TV carga correctamente en desktop y móvil
- [ ] Los lives se muestran en tiempo real
- [ ] El blog pagina correctamente al hacer scroll
- [ ] La búsqueda por cámara no congela el navegador al cambiar de cuenta
- [ ] Los links de LaBodegaTv usan el casing correcto en todas las páginas
```
