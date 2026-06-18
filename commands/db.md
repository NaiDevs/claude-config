---
name: db
description: Activa la conexión de base de datos para un cliente específico y pide reiniciar Claude
---

# db

Habilita la(s) BD del cliente indicado modificando `disabledMcpjsonServers` en `~/.claude/settings.json`.
Requiere reiniciar Claude para que tome efecto.

## Mapeo cliente → servidores

| Alias | Servidores |
|-------|-----------|
| yalo | pg-yalo, ss-yalo |
| bodega | pg-labodega |
| corinsa | pg-corinsa, ss-corinsa |
| ult, ultimatelabs | pg-ultimatelabs |
| emsula | pg-emsula, ss-emsula |
| all | todos |

## Instrucciones

1. Leer `~/.claude/settings.json`
2. Resolver el alias pasado como argumento al mapeo de arriba
3. Quitar esos servidores de `disabledMcpjsonServers`
4. Guardar el archivo
5. Decirle al usuario: "Reiniciá Claude para conectar a [servidores]. Cuando termines usá `/db off` para desactivarlos."

Si se pasa `off` como argumento: agregar TODOS los servidores de DB de vuelta a `disabledMcpjsonServers`.

Si no se pasa argumento: mostrar el estado actual (cuáles están habilitadas y cuáles no).
