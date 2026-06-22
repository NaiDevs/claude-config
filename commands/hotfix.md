---
name: hotfix
description: Use this skill for hotfixes, emergency fixes, critical bugs in production, urgent patches, production errors, fix critico, error en producción, parche urgente, rollback.
---

# /hotfix

Workflow de hotfix — fix mínimo y rápido para producción. Prioridad: tiempo de resolución y no empeorar.

## Cuándo usar

- Error crítico en producción que afecta usuarios
- Servicio caído o endpoint completamente roto
- Vulnerabilidad de seguridad explotada
- Datos incorrectos que se están generando activamente

## Loop de trabajo

```
1. Evaluar severidad (< 5 minutos)
   → ¿Cuántos usuarios afecta?
   → ¿Se puede hacer rollback inmediato? → considerar primero
   → ¿Hay workaround mientras se prepara el fix?

2. Reproducir el problema
   → Confirmar que el error ocurre
   → Identificar el request/acción específica
   → Ver los logs de producción

3. Fix MÍNIMO
   → Tocar solo lo necesario para resolver el problema
   → No aprovechar para refactorizar
   → Si hay duda, hacer el cambio más conservador

4. Validar localmente
   → Reproducir el bug → aplicar fix → confirmar que ya no ocurre
   → Verificar que no se rompió nada más obvio

5. Deploy urgente
   → PR directo a main/master con aprobación rápida
   → Si es solo texto/config: puede ir sin PR (documentar igual)
   → Deploy inmediato

6. Post-hotfix
   → Comunicar resolución al equipo
   → Ticket de follow-up para solución más robusta si el fix fue parche
   → Documentar causa y fix en el commit
```

## Reglas

- Velocidad > perfección, pero no a cualquier costo
- Si el rollback es más rápido que el fix → hacer rollback primero
- Fix mínimo: no tocar lo que no está roto
- Si el fix requiere migración de datos: MUCHO cuidado — preferir fix de código que corrija datos nuevos antes de tocar datos históricos
- Notificar al equipo apenas se confirma el problema

## Template de commit hotfix

```
hotfix(<área>): corrige <descripción corta>

Causa: <qué causaba el bug>
Fix: <qué se cambió y por qué>
Impacto: <qué usuarios/funcionalidad afectó>
```
