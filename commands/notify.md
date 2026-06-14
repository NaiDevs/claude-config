---
description: Notifica cambios a compañeros en Slack — canal, DM o grupo — con resumen de commits del día y menciones automáticas
---

# notify

Envía un mensaje en Slack resumiendo los cambios del día (o commits recientes) al canal, DM o grupo que indiques. Busca automáticamente a los usuarios por nombre y los menciona con @.

## Uso

Escribe la instrucción en lenguaje natural:

```
/notify manda al canal #labodega-dev los cambios que hice a Daniel para que empiece a trabajar
/notify avisa a Daniel por DM que los cambios del checkout están listos para revisar
/notify manda al grupo de yalo-dev un resumen de lo que hice hoy
/notify dile a Edgardo y a Maria en #bodega-dev que el PR ya está listo
/notify [cualquier descripción de a quién, dónde y qué comunicar]
```

## Instrucciones de comportamiento

### Paso 1 — Parsear la instrucción

Extraer de lo que dijo el usuario:
- **Destino**: canal (`#nombre`), DM a persona, grupo existente
- **Personas a mencionar**: nombres propios que aparezcan ("Daniel", "Edgardo", "Maria", etc.)
- **Contexto/mensaje**: qué comunicar ("para que empiece a trabajar", "están listos para revisar", etc.)
- **Proyecto**: si no se menciona, usar el directorio actual o el último proyecto activo

### Paso 2 — Obtener los commits

En el repo del proyecto actual (o del alias si se mencionó):

```
git log --since="00:00" --oneline --format="%h %s" --author=""
```

Si no hay commits de hoy, usar los últimos 5 commits:
```
git log --oneline -5 --format="%h %s"
```

Obtener también el diff stat para saber qué archivos se tocaron:
```
git diff HEAD~N..HEAD --stat   (donde N = cantidad de commits obtenidos)
```

### Paso 3 — Buscar usuarios en Slack

Para cada persona mencionada, usar `slack_search_users` con su nombre.
Guardar el `id` del usuario para armar la mención `<@USER_ID>`.

Si no se encuentra un usuario, informar y preguntar el nombre exacto o handle de Slack.

### Paso 4 — Resolver el destino

**Si es canal** (`#nombre`):
- Usar `slack_search_channels` para encontrar el canal y obtener su ID
- Si no existe, informar

**Si es DM**:
- Buscar el usuario con `slack_search_users`
- Usar `slack_create_conversation` con el user ID para abrir/obtener el DM
- Usar ese conversation ID como destino

**Si es grupo / varios destinatarios**:
- Mencionar a todos en un canal, o
- Crear conversación grupal si el usuario lo pide explícitamente

### Paso 5 — Redactar el mensaje

El mensaje debe ser **natural y directo**, en español, con el contexto del usuario + resumen técnico de los cambios. Formato sugerido:

```
Hola <@USER_ID>! 👋

[Contexto que dio el usuario — ej: "Los cambios del checkout están listos para que empieces a trabajar."]

*Resumen de cambios — [nombre del proyecto] ([fecha])*
• `fix(auth)`: corrige loop infinito al cambiar de cuenta
• `feat(checkout)`: agrega validación de cupones en el carrito

*Archivos principales tocados:*
• `checkout.service.ts` — lógica de cupones
• `auth.context.tsx` — dependencia faltante en useEffect

[Mensaje adicional si el usuario lo especificó — ej: "Avísame si tienes dudas!"]
```

**Reglas del mensaje:**
- Tono conversacional, no robótico
- Máximo 5 archivos en la lista — si hay más, agrupar por módulo
- No incluir hashes de commit completos — solo la descripción
- Mencionar el nombre del proyecto y la rama si es relevante
- No mencionar a Claude ni que fue generado automáticamente

### Paso 6 — Mostrar preview y confirmar

Mostrar el mensaje redactado antes de enviarlo:

```
Destino: #labodega-dev
Menciones: @daniel.brizuela

---
[preview del mensaje]
---

¿Enviamos? (s/editar/n)
```

- `s` → enviar con `slack_send_message`
- `editar` → el usuario corrige y vuelve a confirmar
- `n` → cancelar

### Paso 7 — Enviar

Usar `slack_send_message` con el channel ID y el mensaje.
Confirmar con: "Mensaje enviado a [destino]."

## Casos especiales

### Varios canales o personas
Si el usuario dice "manda a #labodega-dev y a Daniel por DM":
- Enviar el mismo mensaje a ambos destinos
- Confirmar los dos antes de enviar

### Sin commits hoy
Si no hay commits del día:
- Preguntar si quiere usar los últimos N commits o escribir el mensaje manualmente

### Usuario no encontrado en Slack
- Informar: "No encontré a [nombre] en Slack. ¿Cuál es su handle o nombre completo?"
- Reintentar con el dato correcto

### Mensaje solo de texto (sin commits)
Si el usuario solo quiere mandar un aviso sin resumen técnico:
- Omitir la sección de commits y mandar solo el texto de contexto
- Ejemplo: "dile a Daniel que la reunión es a las 3" → DM directo sin commits
