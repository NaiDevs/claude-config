---
description: Genera commits descriptivos en español — analiza el diff staged, lista archivos tocados y confirma antes de ejecutar
---

# commit

Genera un commit descriptivo en español analizando los cambios staged. Muestra qué archivos se tocaron, qué cambió y por qué.

## Uso

```
/commit              → genera el commit con los cambios staged actuales
/commit --all        → hace git add . primero, luego genera el commit
/commit --dry        → muestra el mensaje sin hacer el commit (para revisar)
```

## Instrucciones

### Paso 1 — Leer el estado actual

Correr en paralelo:
- `git diff --staged --stat` — lista de archivos cambiados con líneas +/-
- `git diff --staged` — contenido completo de los cambios
- `git log --oneline -3` — últimos 3 commits para seguir el estilo del repo

Si `--all` fue pasado: correr `git add .` primero, luego los comandos anteriores.
Si no hay nada staged y no se pasó `--all`: informar y sugerir `git add <archivos>` o `/commit --all`.

### Paso 2 — Analizar los cambios

Entender:
- **Qué tipo de cambio es**: feat, fix, refactor, style, chore, docs, test
- **Qué módulo o área** se modificó (componente, endpoint, servicio, etc.)
- **Por qué** se hizo el cambio (si se puede inferir del diff)
- **Qué archivos** se tocaron y cuál fue el cambio principal en cada uno

### Paso 3 — Generar el mensaje de commit

Formato:
```
<tipo>(<alcance>): <descripción corta en imperativo>

Archivos modificados:
- <archivo1>: <qué cambió en una línea>
- <archivo2>: <qué cambió en una línea>
...

<párrafo explicativo si el cambio lo amerita — omitir si es obvio>
```

**Reglas del mensaje:**
- Primera línea: máximo 72 caracteres, imperativo en español ("agrega", "corrige", "elimina", "refactoriza", "actualiza")
- Los tipos en español: `feat`, `fix`, `refactor`, `estilo`, `tarea`, `docs`, `prueba`
- El alcance entre paréntesis es el módulo/componente principal afectado
- Lista de archivos: solo los relevantes — excluir `package-lock.json`, `.gitignore`, archivos de config menores salvo que el cambio sea sobre ellos
- El párrafo explicativo solo si el cambio no es autoexplicativo

**Ejemplos de mensajes bien formados:**
```
feat(checkout): agrega validación de cupones en el resumen del carrito

Archivos modificados:
- cart-summary.component.ts: agrega lógica de descuento por cupón
- cart-summary.component.html: muestra precio tachado y precio final
- checkout.service.ts: expone método validateCoupon()
```

```
fix(auth): corrige loop infinito de re-render al cambiar de cuenta

Archivos modificados:
- auth.context.tsx: agrega dependencia faltante en useEffect
```

```
refactor(home): separa fetching de datos en HomeDynamicSections a llamadas paralelas

Archivos modificados:
- home-dynamic-sections.tsx: reemplaza llamadas secuenciales con Promise.all
```

### Paso 4 — Confirmar y hacer el commit

Si `--dry` fue pasado: mostrar el mensaje propuesto y preguntar si se hace el commit.

Si no: mostrar el mensaje propuesto y preguntar:
```
¿Hacemos el commit con este mensaje? (s/editar/n)
```
- `s` → ejecutar el commit
- `editar` → mostrar el mensaje para que el usuario lo modifique
- `n` → cancelar

### Paso 5 — Ejecutar el commit

```
git commit -m "<mensaje>"
```

Mostrar el hash del commit resultante.

### Paso 6 — Guardar en memoria engram

Después de un commit exitoso, agregar una entrada al archivo de memoria:
`C:\Users\naide\.claude\projects\C--Users-naide\memory\changes-log.md`

Formato de la entrada a agregar al final del archivo:
```
- YYYY-MM-DD | <alias del proyecto activo> | commit | <primera línea del mensaje de commit>
```

Ejemplo:
```
- 2026-06-14 | yalo bo api | commit | fix(auth): corrige validación de token expirado
```

Si no se conoce el alias del proyecto activo, usar el nombre de la carpeta del repo.
Si el archivo supera 100 entradas, eliminar las más antiguas hasta quedar en 100.

## Notas
- No incluir "Co-Authored-By" ni referencias a Claude en el mensaje
- No usar emojis
- Si hay muchos archivos cambiados (más de 10), agrupar por módulo en la lista
