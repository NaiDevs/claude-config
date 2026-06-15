# Guía de variables de entorno para MCPs locales

Estas variables se configuran UNA VEZ por dispositivo como variables de entorno de Windows (no van en ningún archivo del repo).

## Configurar en Windows (permanente, nivel usuario)

Abrir PowerShell y ejecutar:

```powershell
# GitHub — Personal Access Token
# Crear en: https://github.com/settings/tokens
# Permisos: repo, read:org, read:user
[System.Environment]::SetEnvironmentVariable("GITHUB_PERSONAL_ACCESS_TOKEN", "ghp_TU_TOKEN_AQUI", "User")

# PostgreSQL — URL de conexión de desarrollo
# Formato: postgresql://usuario:password@host:5432/nombre_db
[System.Environment]::SetEnvironmentVariable("DATABASE_URL", "postgresql://postgres:password@localhost:5432/dev_db", "User")

# Brave Search — API Key
# Crear en: https://brave.com/search/api/  (gratis hasta 2000 queries/mes)
[System.Environment]::SetEnvironmentVariable("BRAVE_API_KEY", "TU_BRAVE_API_KEY_AQUI", "User")
```

Después de configurar las variables: **cerrar y reabrir Claude Code** para que las tome.

## Variables requeridas por MCP

| MCP | Variable de entorno | Dónde obtener |
|---|---|---|
| GitHub | `GITHUB_PERSONAL_ACCESS_TOKEN` | github.com/settings/tokens → Classic token |
| PostgreSQL | `DATABASE_URL` | Tu DB local de desarrollo |
| Filesystem | — | No necesita token |
| Brave Search | `BRAVE_API_KEY` | brave.com/search/api |
| Memory | — | No necesita token |

## Verificar que están configuradas

```powershell
[System.Environment]::GetEnvironmentVariable("GITHUB_PERSONAL_ACCESS_TOKEN", "User")
[System.Environment]::GetEnvironmentVariable("DATABASE_URL", "User")
[System.Environment]::GetEnvironmentVariable("BRAVE_API_KEY", "User")
```

## Agregar MCPs a settings.json

Abrir `~/.claude/settings.json` y agregar la sección `mcpServers` del archivo `mcp-config.json` de este repo.
Reemplazar `{USERNAME}` con tu nombre de usuario de Windows.

```powershell
# Ver el contenido a agregar
cat "$env:USERPROFILE\.claude\claude-config\mcp-config.json"

# Abrir settings.json para editar
code "$env:USERPROFILE\.claude\settings.json"
```
