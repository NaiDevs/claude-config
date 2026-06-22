---
name: pdfkit
description: Use this skill for PDF generation, PDFKit, reports, invoices, document templates, printable layouts, headers, footers, tables, page breaks, report services, PdfService, builders, replacing Puppeteer-based PDFs, reporte PDF, factura PDF, generar PDF, documento imprimible.
---

# /pdfkit

Workflow para generar PDFs con PDFKit en NestJS. Patrones para facturas, reportes, tablas largas y documentos con header/footer.

## Cuándo usar

- Generar una factura o documento fiscal
- Crear un reporte exportable (listado, resumen, análisis)
- Migrar un PDF de Puppeteer a PDFKit
- Implementar o reutilizar `PdfService` compartido
- Crear un builder para un tipo de documento específico

## Triggers

`PDFKit`, `PDF`, `reporte`, `factura`, `documento`, `PdfService`, `builder`, `header`, `footer`, `tabla`, `salto de página`, `Puppeteer migration`, `generar PDF`, `printable`

## Arquitectura recomendada

```
src/
  common/
    pdf/
      pdf.service.ts          ← PdfService compartido (base, helpers)
      pdf-document.builder.ts ← clase base para documentos
  modules/
    facturas/
      pdf/
        factura-pdf.builder.ts  ← builder específico de factura
      facturas.service.ts
```

## Loop de trabajo

```
1. Definir el documento
   → ¿Qué datos necesita? (entidades, agregaciones)
   → ¿Qué secciones tiene? (header, body, tables, footer)
   → ¿Tiene paginación? ¿múltiples páginas posibles?

2. Construir el PdfService base (si no existe)
   → Inicializa PDFDocument con opciones estándar
   → Header y footer reutilizables
   → Helpers de formato (moneda, fecha, texto largo)

3. Crear el builder específico
   → Recibe los datos como parámetros
   → Llama al PdfService para el scaffolding base
   → Agrega las secciones específicas del documento

4. Exponer desde el controller
   → Response con headers Content-Type y Content-Disposition
   → Stream el PDF directamente al response
   → O devolver Buffer para guardar en storage

5. Manejar casos edge
   → Tabla que supera el alto de la página → salto manual
   → Texto muy largo → truncar o wordwrap
   → Sin datos → página vacía con mensaje
```

## Reglas

- Nunca usar `synchronize: false` → usar streams (PDFKit es stream-based)
- Siempre terminar con `doc.end()` para cerrar el stream
- Para tablas largas: calcular el alto antes de escribir → `doc.y` para saber si cabe
- Headers y footers: agregarlos en el evento `pageAdded` para que aparezcan en cada página
- Fonts: si usas fuente personalizada, incluirla en el proyecto (no depender de sistema)
- Para moneda: `Intl.NumberFormat('es-HN', { style: 'currency', currency: 'HNL' })`
- No hacer `await` dentro del stream de PDFKit — es síncrono

## Implementación base

**PdfService:**
```typescript
// src/common/pdf/pdf.service.ts
import { Injectable } from '@nestjs/common';
import * as PDFDocument from 'pdfkit';

export interface PdfOptions {
  title?: string;
  author?: string;
  margins?: { top: number; bottom: number; left: number; right: number };
}

@Injectable()
export class PdfService {
  createDocument(options: PdfOptions = {}): PDFKit.PDFDocument {
    const doc = new PDFDocument({
      size: 'LETTER',
      margins: options.margins ?? { top: 50, bottom: 50, left: 50, right: 50 },
      info: {
        Title: options.title ?? 'Documento',
        Author: options.author ?? 'Sistema',
      },
      bufferPages: true, // necesario para numerar páginas al final
    });
    return doc;
  }

  // Agrega header con logo y título en cada página nueva
  addPageHeader(doc: PDFKit.PDFDocument, titulo: string, logoPath?: string): void {
    doc.on('pageAdded', () => {
      this.drawHeader(doc, titulo, logoPath);
    });
    this.drawHeader(doc, titulo, logoPath); // primera página
  }

  private drawHeader(doc: PDFKit.PDFDocument, titulo: string, logoPath?: string): void {
    const { left, right, top } = doc.page.margins;
    const width = doc.page.width - left - right;

    if (logoPath) {
      doc.image(logoPath, left, top - 20, { height: 40 });
    }
    doc
      .fontSize(14)
      .font('Helvetica-Bold')
      .text(titulo, left, top - 10, { width, align: 'right' });
    doc
      .moveTo(left, top + 30)
      .lineTo(doc.page.width - right, top + 30)
      .strokeColor('#cccccc')
      .stroke();
    doc.moveDown(2);
  }

  // Agrega footer con número de página
  addPageNumbers(doc: PDFKit.PDFDocument): void {
    const range = doc.bufferedPageRange();
    for (let i = range.start; i < range.start + range.count; i++) {
      doc.switchToPage(i);
      doc
        .fontSize(8)
        .font('Helvetica')
        .fillColor('#888888')
        .text(
          `Página ${i + 1} de ${range.count}`,
          doc.page.margins.left,
          doc.page.height - 40,
          { align: 'right' },
        );
    }
  }

  // Helper: tabla simple
  drawTable(
    doc: PDFKit.PDFDocument,
    headers: string[],
    rows: string[][],
    colWidths: number[],
    x?: number,
    y?: number,
  ): void {
    const startX = x ?? doc.page.margins.left;
    const startY = y ?? doc.y;
    const rowHeight = 20;
    const pageBottom = doc.page.height - doc.page.margins.bottom - 20;

    // Header de tabla
    doc.font('Helvetica-Bold').fontSize(9);
    let currentX = startX;
    headers.forEach((h, i) => {
      doc.text(h, currentX + 4, startY + 4, { width: colWidths[i] - 8, lineBreak: false });
      currentX += colWidths[i];
    });
    doc.rect(startX, startY, colWidths.reduce((a, b) => a + b, 0), rowHeight).stroke();

    // Filas
    doc.font('Helvetica').fontSize(8);
    let currentY = startY + rowHeight;
    rows.forEach((row) => {
      // Salto de página si no cabe la fila
      if (currentY + rowHeight > pageBottom) {
        doc.addPage();
        currentY = doc.page.margins.top;
      }
      currentX = startX;
      row.forEach((cell, i) => {
        doc.text(cell, currentX + 4, currentY + 4, { width: colWidths[i] - 8, lineBreak: false });
        currentX += colWidths[i];
      });
      doc.rect(startX, currentY, colWidths.reduce((a, b) => a + b, 0), rowHeight).stroke();
      currentY += rowHeight;
    });
    doc.y = currentY + 5;
  }

  // Convertir stream a Buffer (para guardar en S3 o retornar desde endpoint)
  streamToBuffer(doc: PDFKit.PDFDocument): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const chunks: Buffer[] = [];
      doc.on('data', (chunk) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);
      doc.end();
    });
  }
}
```

**Builder de factura:**
```typescript
// src/modules/facturas/pdf/factura-pdf.builder.ts
@Injectable()
export class FacturaPdfBuilder {
  constructor(private readonly pdfService: PdfService) {}

  async buildFactura(factura: Factura): Promise<Buffer> {
    const doc = this.pdfService.createDocument({ title: `Factura #${factura.numero}` });
    this.pdfService.addPageHeader(doc, `Factura #${factura.numero}`);

    // Datos del encabezado
    doc
      .fontSize(10)
      .font('Helvetica')
      .text(`Cliente: ${factura.cliente.nombre}`)
      .text(`Fecha: ${factura.fecha.toLocaleDateString('es-HN')}`)
      .text(`RTN: ${factura.cliente.rtn ?? 'N/A'}`)
      .moveDown();

    // Tabla de detalle
    this.pdfService.drawTable(
      doc,
      ['Descripción', 'Cantidad', 'Precio Unit.', 'Total'],
      factura.detalles.map((d) => [
        d.descripcion,
        d.cantidad.toString(),
        this.formatMoneda(d.precioUnitario),
        this.formatMoneda(d.total),
      ]),
      [280, 60, 90, 90],
    );

    // Totales
    doc
      .moveDown()
      .font('Helvetica-Bold')
      .text(`Subtotal: ${this.formatMoneda(factura.subtotal)}`, { align: 'right' })
      .text(`ISV 15%: ${this.formatMoneda(factura.isv)}`, { align: 'right' })
      .text(`Total: ${this.formatMoneda(factura.total)}`, { align: 'right' });

    this.pdfService.addPageNumbers(doc);
    return this.pdfService.streamToBuffer(doc);
  }

  private formatMoneda(valor: number): string {
    return new Intl.NumberFormat('es-HN', {
      style: 'currency',
      currency: 'HNL',
    }).format(valor);
  }
}
```

**Controller — stream al response:**
```typescript
@Get(':id/pdf')
@UseGuards(JwtAuthGuard)
@Header('Content-Type', 'application/pdf')
async downloadPdf(
  @Param('id') id: string,
  @Res() res: Response,
) {
  const factura = await this.facturasService.findOne(+id);
  const buffer = await this.facturaPdfBuilder.buildFactura(factura);
  res.setHeader('Content-Disposition', `attachment; filename="factura-${factura.numero}.pdf"`);
  res.setHeader('Content-Length', buffer.length);
  res.end(buffer);
}
```

## Migración desde Puppeteer

```
Puppeteer genera PDF desde HTML → lento, requiere Chromium, no recomendado en server
PDFKit genera PDF programáticamente → más rápido, sin dependencias de browser

Mapeo:
- HTML table → pdfService.drawTable()
- CSS font-weight: bold → doc.font('Helvetica-Bold')
- HTML <br> → doc.moveDown()
- CSS page-break → doc.addPage()
- window.print() → pdfService.streamToBuffer()
```
