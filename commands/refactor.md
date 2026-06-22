---
name: refactor
description: Use this skill for refactoring, code cleanup, extracting services, extracting components, removing duplication, improving naming, splitting large files, improving TypeScript types, improving architecture without changing behavior, refactorizar, limpiar código, extraer servicio, mejorar arquitectura.
---

# /refactor

Workflow de refactoring controlado. Mejora la estructura sin cambiar el comportamiento.

## Cuándo usar

- Archivo o función demasiado larga (> 200 líneas en un método → refactorizar)
- Duplicación obvia entre dos servicios o componentes
- Nombres confusos que dificultan entender el código
- Lógica de negocio en el controller o en el template Angular
- Tipos `any` que se pueden tipar correctamente

## Reglas

- **El comportamiento no cambia** — refactoring no es agregar features
- Hacer cambios pequeños y verificables, no todo de una vez
- Tener tests antes de refactorizar código crítico
- Si no hay tests: agregar al menos un test del caso principal primero
- Commits separados: un commit por tipo de refactoring

## Loop de trabajo

```
1. Identificar el problema específico
   → ¿Qué huele mal? (long method, god service, magic numbers, etc.)
   → ¿Qué beneficio concreto tiene el refactoring?

2. Verificar cobertura
   → ¿Hay tests que verifica el comportamiento actual?
   → Si no: escribir uno antes de refactorizar

3. Refactorizar paso a paso
   → Un cambio a la vez
   → Verificar que el comportamiento no cambió después de cada paso

4. Revisar tipos
   → Reemplazar 'any' con tipos correctos
   → Agregar interfaces donde corresponda

5. Commit por separado
   → No mezclar refactoring con features en el mismo commit
```

## Patrones frecuentes

**Extraer servicio (God Service → servicios específicos):**
```typescript
// ANTES: FacturasService hace todo
class FacturasService {
  createFactura() { ... }
  sendEmailNotification() { ... }  // ← no es responsabilidad de facturas
  generatePdf() { ... }            // ← no es responsabilidad de facturas
}

// DESPUÉS: responsabilidades separadas
class FacturasService {
  constructor(
    private emailService: EmailService,    // inyectado
    private pdfService: PdfService,        // inyectado
  ) {}
  createFactura() { ... }
}
```

**Extraer método largo:**
```typescript
// ANTES: createFactura hace 80 líneas
async createFactura(dto) {
  // validar cliente
  // calcular subtotal
  // calcular ISV
  // generar número de factura
  // guardar en DB
  // enviar email
  // ...
}

// DESPUÉS: métodos claros
async createFactura(dto) {
  const cliente = await this.validateCliente(dto.clienteId);
  const totales = this.calculateTotals(dto.detalles);
  const numero = await this.generateNumero();
  const factura = await this.saveFactura(dto, cliente, totales, numero);
  await this.notifyCreation(factura);
  return factura;
}
```
