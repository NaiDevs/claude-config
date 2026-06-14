---
name: setup-claude-config
description: "claude-config repo location and structure — portable config with project aliases, workspaces and /proyecto skill"
metadata: 
  node_type: memory
  type: reference
  originSessionId: baa97b0f-6550-4a98-92f2-501e6aea9d37
---

El sistema de configuración de proyectos está en `C:\Users\naide\.claude\claude-config\` como repo git.

Estructura del repo:
- `projects-registry.md` — fuente de verdad de aliases y workspaces (editable)
- `skills/proyecto.md` — definición del skill `/proyecto`
- `memory/` — archivos de memoria por cliente
- `setup.ps1` — instalador para nuevo dispositivo
- `settings-hook.json` — fragmento para hook de git fetch automático

Archivos instalados en runtime:
- `~/.claude/projects-registry.md` — copia del registry (edita aquí para cambios rápidos)
- `~/.claude/skills/proyecto.md` — skill activo
- `~/.claude/projects/C--Users-naide/memory/*.md` — memoria activa

Para sincronizar cambios del registry a otro dispositivo:
1. Editar `~/.claude/projects-registry.md`
2. Copiar de vuelta al repo: `cp ~/.claude/projects-registry.md ~/.claude/claude-config/`
3. Hacer commit y push
4. En otro dispositivo: `git pull` + `.\setup.ps1`

Para subir el repo a GitHub: crear repo privado y hacer `git remote add origin <url> && git push -u origin master`.
