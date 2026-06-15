---
description: Asistente para generación de documentos — PDFs con QuestPDF (.NET) y pdfmake (NestJS), Excel con ClosedXML (.NET) y ExcelJS (NestJS/Angular)
---

# docs

Asistente para generación de documentos en los proyectos. Cubre PDFs y Excel tanto en .NET (QuestPDF, ClosedXML) como en NestJS/Angular (pdfmake, ExcelJS, jsPDF).

## Uso

```
/docs pdf <nombre>                    → genera PDF con QuestPDF (.NET) o pdfmake (NestJS)
/docs pdf table <nombre>              → PDF con tabla de datos
/docs pdf invoice <nombre>            → plantilla de factura/reporte formal
/docs excel <nombre>                  → genera Excel con ClosedXML (.NET) o ExcelJS (NestJS)
/docs excel table <nombre>            → Excel con tabla de datos y estilos
/docs excel template <nombre>         → Excel con encabezado, datos y totales
/docs download angular                → descarga de archivo desde Angular (blob)
/docs download nextjs                 → descarga desde Next.js (route handler)
```

## Librería por proyecto

| Alias | Tipo | Librería |
|---|---|---|
| yalo reporteria (.NET 8) | PDF + Excel | **QuestPDF** 2025.7 + **ClosedXML** 0.105 |
| yalo bo api (.NET) | Excel | **ClosedXML** |
| yalo admin api (NestJS) | PDF + Excel | **pdfmake** + **ExcelJS** |
| bodega bo api (NestJS) | Excel | **ExcelJS** 4.x |
| yalo bo (Angular POS) | PDF | **jsPDF** + **Excel** xlsx |

---

## QuestPDF — .NET (YALO Reportería)

### `/docs pdf <nombre>` — PDF básico con QuestPDF

```csharp
// Infrastructure/Reports/<Nombre>Report.cs
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

public class <Nombre>Report : IDocument
{
    private readonly <Nombre>ReportData _data;

    public <Nombre>Report(<Nombre>ReportData data) => _data = data;

    public DocumentMetadata GetMetadata() => DocumentMetadata.Default;

    public void Compose(IDocumentContainer container)
    {
        container.Page(page =>
        {
            page.Size(PageSizes.A4);
            page.Margin(2, Unit.Centimetre);
            page.DefaultTextStyle(x => x.FontSize(11).FontFamily("Arial"));

            page.Header().Element(ComposeHeader);
            page.Content().Element(ComposeContent);
            page.Footer().Element(ComposeFooter);
        });
    }

    private void ComposeHeader(IContainer container)
    {
        container.Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text(_data.TituloReporte)
                   .FontSize(18).Bold().FontColor(Colors.Indigo.Darken2);
                col.Item().Text($"Generado: {_data.Fecha:dd/MM/yyyy HH:mm}")
                   .FontSize(9).FontColor(Colors.Grey.Darken1);
            });

            row.ConstantItem(100).Image("wwwroot/logo.png");
        });
    }

    private void ComposeContent(IContainer container)
    {
        container.PaddingTop(20).Column(col =>
        {
            // Sección de información
            col.Item().Background(Colors.Grey.Lighten3).Padding(10).Row(row =>
            {
                row.RelativeItem().Text($"Cliente: {_data.ClienteNombre}").Bold();
                row.RelativeItem().Text($"Período: {_data.PeriodoDescripcion}");
            });

            col.Item().PaddingTop(15).Element(ComposeTable);
        });
    }

    private void ComposeTable(IContainer container)
    {
        container.Table(table =>
        {
            // Columnas
            table.ColumnsDefinition(cols =>
            {
                cols.ConstantColumn(30);      // #
                cols.RelativeColumn(3);       // Nombre
                cols.RelativeColumn(2);       // Categoría
                cols.ConstantColumn(80);      // Monto
            });

            // Encabezado
            table.Header(header =>
            {
                header.Cell().Background(Colors.Indigo.Darken2)
                      .Padding(5).Text("#").FontColor(Colors.White).Bold();
                header.Cell().Background(Colors.Indigo.Darken2)
                      .Padding(5).Text("Nombre").FontColor(Colors.White).Bold();
                header.Cell().Background(Colors.Indigo.Darken2)
                      .Padding(5).Text("Categoría").FontColor(Colors.White).Bold();
                header.Cell().Background(Colors.Indigo.Darken2)
                      .Padding(5).Text("Monto").FontColor(Colors.White).Bold();
            });

            // Filas
            var i = 1;
            foreach (var item in _data.Items)
            {
                var bg = i % 2 == 0 ? Colors.Grey.Lighten4 : Colors.White;
                table.Cell().Background(bg).Padding(5).Text(i.ToString());
                table.Cell().Background(bg).Padding(5).Text(item.Nombre);
                table.Cell().Background(bg).Padding(5).Text(item.Categoria);
                table.Cell().Background(bg).Padding(5)
                     .Text($"L. {item.Monto:N2}").AlignRight();
                i++;
            }

            // Total
            table.Cell().ColumnSpan(3).Background(Colors.Indigo.Lighten4)
                 .Padding(5).Text("TOTAL").Bold().AlignRight();
            table.Cell().Background(Colors.Indigo.Lighten4)
                 .Padding(5).Text($"L. {_data.Items.Sum(x => x.Monto):N2}").Bold().AlignRight();
        });
    }

    private void ComposeFooter(IContainer container)
    {
        container.Row(row =>
        {
            row.RelativeItem().Text(x =>
            {
                x.Span("Página ").FontSize(9).FontColor(Colors.Grey.Medium);
                x.CurrentPageNumber().FontSize(9);
                x.Span(" de ").FontSize(9).FontColor(Colors.Grey.Medium);
                x.TotalPages().FontSize(9);
            });
        });
    }
}

// Generar bytes desde el controller
[HttpGet("{id}/pdf")]
public async Task<IActionResult> DescargarReporte(int id)
{
    var data = await _reporteService.GetReportDataAsync(id);
    var pdf  = new <Nombre>Report(data).GeneratePdf();

    return File(pdf, "application/pdf", $"reporte-{id}.pdf");
}
```

---

## ClosedXML — .NET (YALO APIs)

### `/docs excel table <nombre>`

```csharp
// Infrastructure/Exports/<Nombre>ExcelExport.cs
using ClosedXML.Excel;

public class <Nombre>ExcelExport
{
    public byte[] Generate(IEnumerable<<Nombre>ExportDto> items, string titulo)
    {
        using var workbook  = new XLWorkbook();
        var sheet = workbook.Worksheets.Add(titulo);

        // Configuración general
        sheet.ShowGridLines     = false;
        sheet.PageSetup.Orientation = XLPageOrientation.Landscape;

        var fila = 1;

        // Título principal
        sheet.Cell(fila, 1).Value = titulo;
        sheet.Range(fila, 1, fila, 5).Merge();
        sheet.Cell(fila, 1).Style
             .Font.SetBold().Font.SetFontSize(14)
             .Alignment.SetHorizontal(XLAlignmentHorizontalValues.Center)
             .Fill.SetBackgroundColor(XLColor.FromHtml("#3730a3"))
             .Font.SetFontColor(XLColor.White);
        fila++;

        // Subtítulo con fecha
        sheet.Cell(fila, 1).Value = $"Generado: {DateTime.Now:dd/MM/yyyy HH:mm}";
        sheet.Range(fila, 1, fila, 5).Merge();
        sheet.Cell(fila, 1).Style.Font.SetFontSize(9).Font.SetFontColor(XLColor.Gray);
        fila += 2;

        // Encabezados de columnas
        var headers = new[] { "#", "Nombre", "Categoría", "Fecha", "Monto" };
        for (int c = 0; c < headers.Length; c++)
        {
            sheet.Cell(fila, c + 1).Value = headers[c];
            sheet.Cell(fila, c + 1).Style
                 .Font.SetBold()
                 .Fill.SetBackgroundColor(XLColor.FromHtml("#e0e7ff"))
                 .Border.SetBottomBorder(XLBorderStyleValues.Medium)
                 .Border.SetBottomBorderColor(XLColor.FromHtml("#3730a3"))
                 .Alignment.SetHorizontal(XLAlignmentHorizontalValues.Center);
        }
        fila++;

        // Datos
        var filaInicioDatos = fila;
        var i = 1;
        foreach (var item in items)
        {
            var bg = i % 2 == 0 ? XLColor.FromHtml("#f8fafc") : XLColor.White;
            sheet.Cell(fila, 1).Value = i;
            sheet.Cell(fila, 2).Value = item.Nombre;
            sheet.Cell(fila, 3).Value = item.Categoria;
            sheet.Cell(fila, 4).Value = item.Fecha;
            sheet.Cell(fila, 4).Style.NumberFormat.Format = "dd/mm/yyyy";
            sheet.Cell(fila, 5).Value = item.Monto;
            sheet.Cell(fila, 5).Style.NumberFormat.Format = "\"L. \"#,##0.00";

            sheet.Range(fila, 1, fila, 5).Style.Fill.SetBackgroundColor(bg);
            fila++; i++;
        }

        // Fila de totales
        sheet.Cell(fila, 4).Value = "TOTAL";
        sheet.Cell(fila, 4).Style.Font.SetBold().Alignment.SetHorizontal(XLAlignmentHorizontalValues.Right);
        sheet.Cell(fila, 5).FormulaA1 = $"=SUM(E{filaInicioDatos}:E{fila - 1})";
        sheet.Cell(fila, 5).Style.Font.SetBold().NumberFormat.Format = "\"L. \"#,##0.00"
             .Fill.SetBackgroundColor(XLColor.FromHtml("#e0e7ff"));

        // Auto-ajustar columnas
        sheet.Columns().AdjustToContents(8, 50);

        // Generar bytes
        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return stream.ToArray();
    }
}

// Endpoint para descarga
[HttpGet("exportar")]
public async Task<IActionResult> Exportar()
{
    var items = await _service.GetAllForExportAsync();
    var bytes = new <Nombre>ExcelExport().Generate(items, "<Nombre>s");
    return File(bytes,
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        $"<nombre>s-{DateTime.Now:yyyyMMdd}.xlsx");
}
```

---

## ExcelJS — NestJS (La Bodega, YALO Admin)

### `/docs excel template <nombre>`

```typescript
// src/exports/<nombre>.excel.ts
import { Workbook, Worksheet } from 'exceljs';
import { Response } from 'express';

export async function generate<Nombre>Excel(
  items: <Nombre>ExportDto[],
  titulo: string,
  res: Response,
): Promise<void> {
  const wb    = new Workbook();
  const sheet = wb.addWorksheet(titulo);

  // Estilos reutilizables
  const headerStyle = {
    font:      { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 },
    fill:      { type: 'pattern' as const, pattern: 'solid' as const, fgColor: { argb: 'FF3730A3' } },
    alignment: { horizontal: 'center' as const, vertical: 'middle' as const },
    border:    { bottom: { style: 'medium' as const } },
  };

  // Título del reporte
  sheet.mergeCells('A1:E1');
  sheet.getCell('A1').value = titulo;
  sheet.getCell('A1').font  = { bold: true, size: 14, color: { argb: 'FF3730A3' } };
  sheet.getCell('A1').alignment = { horizontal: 'center' };
  sheet.getRow(1).height = 30;

  // Fecha de generación
  sheet.getCell('A2').value = `Generado: ${new Date().toLocaleString('es-HN')}`;
  sheet.getCell('A2').font  = { size: 9, color: { argb: 'FF6B7280' } };
  sheet.getRow(3).height = 5; // separador

  // Encabezados
  const headers = ['#', 'Nombre', 'Categoría', 'Fecha', 'Monto (L.)'];
  const headerRow = sheet.addRow(headers);
  headerRow.height = 25;
  headerRow.eachCell(cell => Object.assign(cell, headerStyle));

  // Anchos de columna
  sheet.getColumn(1).width = 6;
  sheet.getColumn(2).width = 35;
  sheet.getColumn(3).width = 20;
  sheet.getColumn(4).width = 15;
  sheet.getColumn(5).width = 15;

  // Datos
  let total = 0;
  items.forEach((item, idx) => {
    const row = sheet.addRow([
      idx + 1,
      item.nombre,
      item.categoria,
      item.fecha,
      item.monto,
    ]);

    // Formato de fecha y número
    row.getCell(4).numFmt = 'dd/mm/yyyy';
    row.getCell(5).numFmt = '"L. "#,##0.00';

    // Filas alternadas
    if (idx % 2 === 0) {
      row.eachCell(cell => {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8FAFC' } };
      });
    }

    total += item.monto;
  });

  // Fila de total
  const totalRow = sheet.addRow(['', '', '', 'TOTAL', total]);
  totalRow.getCell(4).font = { bold: true };
  totalRow.getCell(5).numFmt = '"L. "#,##0.00';
  totalRow.getCell(5).font  = { bold: true };
  totalRow.eachCell(cell => {
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E7FF' } };
  });

  // Enviar al cliente
  res.setHeader('Content-Type',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition',
    `attachment; filename="${titulo}-${Date.now()}.xlsx"`);

  await wb.xlsx.write(res);
  res.end();
}
```

```typescript
// En el controller NestJS
@Get('exportar')
@UseGuards(JwtAuthGuard)
async exportar(@Res() res: Response) {
  const items = await this.service.getAllForExport();
  await generate<Nombre>Excel(items, '<Nombre>s', res);
}
```

---

## pdfmake — NestJS (YALO Admin)

### `/docs pdf invoice <nombre>` — Factura/reporte con pdfmake

```typescript
import PdfPrinter from 'pdfmake';
import { TDocumentDefinitions } from 'pdfmake/interfaces';

const fonts = {
  Roboto: {
    normal:      'node_modules/pdfmake/build/vfs_fonts.js',
    bold:        'node_modules/pdfmake/build/vfs_fonts.js',
    italics:     'node_modules/pdfmake/build/vfs_fonts.js',
    bolditalics: 'node_modules/pdfmake/build/vfs_fonts.js',
  },
};

export function generate<Nombre>Pdf(data: <Nombre>PdfData): Promise<Buffer> {
  const printer = new PdfPrinter(fonts);

  const docDefinition: TDocumentDefinitions = {
    pageSize: 'A4',
    pageMargins: [40, 60, 40, 60],
    styles: {
      header:    { fontSize: 18, bold: true, color: '#3730a3' },
      subheader: { fontSize: 11, bold: true, margin: [0, 10, 0, 5] },
      tableHeader: { bold: true, fillColor: '#3730a3', color: '#ffffff',
                     fontSize: 10, alignment: 'center' },
    },
    content: [
      // Header
      {
        columns: [
          { text: data.titulo, style: 'header' },
          { text: `Fecha: ${new Date().toLocaleDateString('es-HN')}`,
            alignment: 'right', fontSize: 10, color: '#6b7280' },
        ],
        margin: [0, 0, 0, 20],
      },
      // Info del cliente
      {
        table: {
          widths: ['*', '*'],
          body: [
            [{ text: 'Cliente:', bold: true }, data.clienteNombre],
            [{ text: 'Período:', bold: true }, data.periodo],
          ],
        },
        layout: 'noBorders',
        margin: [0, 0, 0, 20],
      },
      // Tabla de datos
      {
        table: {
          headerRows: 1,
          widths: [30, '*', 100, 80],
          body: [
            [
              { text: '#',        style: 'tableHeader' },
              { text: 'Nombre',   style: 'tableHeader' },
              { text: 'Fecha',    style: 'tableHeader' },
              { text: 'Monto',    style: 'tableHeader' },
            ],
            ...data.items.map((item, i) => [
              { text: (i + 1).toString(), alignment: 'center' },
              item.nombre,
              { text: new Date(item.fecha).toLocaleDateString('es-HN'), alignment: 'center' },
              { text: `L. ${item.monto.toFixed(2)}`, alignment: 'right' },
            ]),
            // Fila total
            [
              { text: 'TOTAL', colSpan: 3, alignment: 'right', bold: true,
                fillColor: '#e0e7ff' },
              {}, {},
              { text: `L. ${data.items.reduce((s, i) => s + i.monto, 0).toFixed(2)}`,
                alignment: 'right', bold: true, fillColor: '#e0e7ff' },
            ],
          ],
        },
        layout: {
          fillColor: (row) => row % 2 === 0 && row > 0 ? '#f8fafc' : null,
        },
      },
    ],
    footer: (page, pages) => ({
      columns: [
        { text: `Página ${page} de ${pages}`, alignment: 'center',
          fontSize: 9, color: '#9ca3af' },
      ],
    }),
  };

  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    const doc = printer.createPdfKitDocument(docDefinition);
    doc.on('data',  chunk => chunks.push(Buffer.from(chunk)));
    doc.on('end',   () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    doc.end();
  });
}
```

---

## Descarga desde Angular

### `/docs download angular`

```typescript
// Descargar desde el backend
downloadReport(id: number): void {
  this.http.get(`/api/reportes/${id}/pdf`, { responseType: 'blob' })
    .subscribe(blob => {
      const url  = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href     = url;
      link.download = `reporte-${id}.pdf`;
      link.click();
      URL.revokeObjectURL(url);
    });
}

downloadExcel(filtros: any): void {
  this.http.post(`/api/reportes/exportar`, filtros, { responseType: 'blob' })
    .subscribe(blob => {
      const url  = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href     = url;
      link.download = `reporte-${Date.now()}.xlsx`;
      link.click();
      URL.revokeObjectURL(url);
    });
}
```

### `/docs download nextjs` — Route handler

```typescript
// app/api/reportes/[id]/pdf/route.ts
export async function GET(request: Request, { params }: { params: { id: string } }) {
  const pdfBuffer = await generateReportePdf(parseInt(params.id));

  return new Response(pdfBuffer, {
    headers: {
      'Content-Type':        'application/pdf',
      'Content-Disposition': `attachment; filename="reporte-${params.id}.pdf"`,
    },
  });
}
```
