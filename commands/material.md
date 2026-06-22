---
name: material
description: Use this skill for Angular Material components, mat-table, mat-dialog, mat-form-field, mat-input, mat-select, mat-button, mat-icon, mat-toolbar, mat-sidenav, mat-paginator, mat-sort, MatDialog, MatSnackBar, MatFormFieldModule, ReactiveFormsModule with Material, Material theming, CDK, Angular Material 15+, tabla Angular Material, dialog Angular Material, formulario Material, paginador Material.
---

# material

Asistente para Angular Material. Detecta la versión instalada en el proyecto activo y genera código con los imports y APIs correctas (Material 7 vs 15+ tiene imports diferentes).

## Uso

```
/material table <nombre>          → tabla con MatTable + paginación + sorting + filtro
/material form <nombre>           → formulario con mat-form-field, validaciones y errores
/material dialog <nombre>         → dialog completo (trigger + componente + tipos)
/material sidenav <nombre>        → layout con sidenav + toolbar
/material stepper <nombre>        → stepper multi-paso
/material select <nombre>         → select con búsqueda (mat-select + filter)
/material datepicker <nombre>     → campo de fecha con mat-datepicker
/material chips <nombre>          → input de chips (tags)
/material autocomplete <nombre>   → campo con autocompletado
/material theme                   → genera o actualiza el tema de Material
/material snack <mensaje>         → snippet para mostrar MatSnackBar
/material drag <nombre>           → lista con CDK drag-and-drop
```

## Instrucciones de comportamiento

### Paso 1 — Detectar versión de Angular Material

Leer `package.json` del proyecto activo y buscar `@angular/material`.

| Versión Material | Diferencia clave |
|---|---|
| v7-v14 | `MatXxxModule` importado en NgModule |
| v15+ standalone | `MatXxxModule` importado directo en el componente, o imports individuales |
| v17+ | Soporta `inject()`, signals, `mat-icon` con `fontIcon` |

### Generadores

#### `/material table <nombre>`

Genera componente completo con `MatTable`, `MatPaginator`, `MatSort` y filtro por texto.

**Template:**
```html
<div class="flex flex-col gap-4 p-4">
  <!-- Filtro -->
  <mat-form-field appearance="outline" class="w-full max-w-sm">
    <mat-label>Buscar</mat-label>
    <input matInput (keyup)="applyFilter($event)" placeholder="Filtrar...">
    <mat-icon matSuffix>search</mat-icon>
  </mat-form-field>

  <!-- Tabla -->
  <div class="overflow-auto rounded-lg shadow">
    <table mat-table [dataSource]="dataSource" matSort class="w-full">

      <!-- Columna nombre -->
      <ng-container matColumnDef="nombre">
        <th mat-header-cell *matHeaderCellDef mat-sort-header>Nombre</th>
        <td mat-cell *matCellDef="let row">{{ row.nombre }}</td>
      </ng-container>

      <!-- Columna acciones -->
      <ng-container matColumnDef="acciones">
        <th mat-header-cell *matHeaderCellDef>Acciones</th>
        <td mat-cell *matCellDef="let row">
          <button mat-icon-button color="primary" (click)="onEdit(row)">
            <mat-icon>edit</mat-icon>
          </button>
          <button mat-icon-button color="warn" (click)="onDelete(row)">
            <mat-icon>delete</mat-icon>
          </button>
        </td>
      </ng-container>

      <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
      <tr mat-row *matRowDef="let row; columns: displayedColumns;"
          class="hover:bg-gray-50 cursor-pointer"></tr>

      <!-- Sin resultados -->
      <tr class="mat-row" *matNoDataRow>
        <td class="mat-cell text-center py-8 text-gray-500" [attr.colspan]="displayedColumns.length">
          No se encontraron resultados
        </td>
      </tr>
    </table>
  </div>

  <mat-paginator [pageSizeOptions]="[10, 25, 50]" showFirstLastButtons></mat-paginator>
</div>
```

**TypeScript:**
```typescript
@Component({ /* ... */ })
export class <Nombre>TableComponent implements OnInit, AfterViewInit {
  displayedColumns = ['nombre', 'acciones'];
  dataSource = new MatTableDataSource<<Nombre>>([]);

  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  // Angular 15+: inject() | Angular < 15: constructor DI
  private service = inject(<Nombre>Service);

  ngOnInit() {
    this.service.getAll().subscribe(data => this.dataSource.data = data);
  }

  ngAfterViewInit() {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  applyFilter(event: Event) {
    const value = (event.target as HTMLInputElement).value;
    this.dataSource.filter = value.trim().toLowerCase();
    this.dataSource.paginator?.firstPage();
  }

  onEdit(row: <Nombre>) { /* abrir dialog */ }
  onDelete(row: <Nombre>) { /* confirmar y eliminar */ }
}
```

Preguntar qué columnas tiene la entidad antes de generar.

---

#### `/material form <nombre>`

Genera formulario reactivo con `mat-form-field` para cada campo, mensajes de error automáticos y botones de acción.

```html
<form [formGroup]="form" (ngSubmit)="onSubmit()" class="flex flex-col gap-4">

  <mat-form-field appearance="outline">
    <mat-label>Nombre</mat-label>
    <input matInput formControlName="nombre" placeholder="Ingresa el nombre">
    <mat-error *ngIf="form.get('nombre')?.hasError('required')">
      El nombre es requerido
    </mat-error>
    <mat-error *ngIf="form.get('nombre')?.hasError('minlength')">
      Mínimo {{ form.get('nombre')?.errors?.['minlength']?.requiredLength }} caracteres
    </mat-error>
  </mat-form-field>

  <mat-form-field appearance="outline">
    <mat-label>Email</mat-label>
    <input matInput formControlName="email" type="email">
    <mat-icon matSuffix>email</mat-icon>
    <mat-error *ngIf="form.get('email')?.hasError('email')">
      Email inválido
    </mat-error>
  </mat-form-field>

  <div class="flex gap-2 justify-end">
    <button mat-button type="button" (click)="onCancel()">Cancelar</button>
    <button mat-raised-button color="primary" type="submit" [disabled]="form.invalid || loading">
      <mat-icon *ngIf="loading">
        <mat-spinner diameter="20"></mat-spinner>
      </mat-icon>
      Guardar
    </button>
  </div>
</form>
```

```typescript
form = inject(FormBuilder).group({
  nombre: ['', [Validators.required, Validators.minLength(3)]],
  email:  ['', [Validators.required, Validators.email]],
});
```

Preguntar los campos y sus validaciones antes de generar.

---

#### `/material dialog <nombre>`

Genera el dialog completo: botón de apertura, componente del dialog, interfaz de datos y tipo de retorno.

```typescript
// tipos
export interface <Nombre>DialogData { item?: <Nombre>; }
export type <Nombre>DialogResult = <Nombre> | undefined;

// componente del dialog
@Component({
  selector: 'app-<nombre>-dialog',
  standalone: true,
  imports: [MatDialogModule, MatButtonModule, ReactiveFormsModule, MatFormFieldModule, MatInputModule],
  template: `
    <h2 mat-dialog-title>{{ data.item ? 'Editar' : 'Crear' }} <Nombre></h2>
    <mat-dialog-content>
      <form [formGroup]="form" class="flex flex-col gap-3 pt-2">
        <mat-form-field appearance="outline">
          <mat-label>Nombre</mat-label>
          <input matInput formControlName="nombre">
        </mat-form-field>
      </form>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button mat-dialog-close>Cancelar</button>
      <button mat-raised-button color="primary"
              [disabled]="form.invalid"
              (click)="onConfirm()">
        Guardar
      </button>
    </mat-dialog-actions>
  `
})
export class <Nombre>DialogComponent {
  data = inject<{ item?: <Nombre> }>(MAT_DIALOG_DATA);
  private dialogRef = inject(MatDialogRef<<Nombre>DialogComponent>);
  form = inject(FormBuilder).group({ nombre: [this.data.item?.nombre ?? '', Validators.required] });

  onConfirm() {
    if (this.form.valid) this.dialogRef.close(this.form.value);
  }
}

// cómo abrirlo desde otro componente
private dialog = inject(MatDialog);

openDialog(item?: <Nombre>) {
  this.dialog.open<<Nombre>DialogComponent, <Nombre>DialogData, <Nombre>DialogResult>(
    <Nombre>DialogComponent,
    { data: { item }, width: '480px' }
  ).afterClosed().subscribe(result => {
    if (result) this.save(result);
  });
}
```

---

#### `/material snack <mensaje>`

Snippet para usar en cualquier componente:
```typescript
private snack = inject(MatSnackBar);

// Éxito
this.snack.open('<mensaje>', 'Cerrar', {
  duration: 3000,
  panelClass: ['snack-success'],
  horizontalPosition: 'end',
  verticalPosition: 'top'
});

// Error
this.snack.open('Ocurrió un error', 'Cerrar', {
  duration: 5000,
  panelClass: ['snack-error'],
});
```

---

#### `/material theme`

Genera configuración de tema personalizado en `styles.scss`:

```scss
// Material 17+ (nueva API de theming)
@use '@angular/material' as mat;

$primary: mat.define-palette(mat.$indigo-palette, 700);
$accent:  mat.define-palette(mat.$amber-palette, A200, A100, A400);
$warn:    mat.define-palette(mat.$red-palette);

$theme: mat.define-light-theme((
  color: (primary: $primary, accent: $accent, warn: $warn),
  typography: mat.define-typography-config(),
  density: 0,
));

@include mat.all-component-themes($theme);
```

Preguntar los colores primario y de acento antes de generar.

---

#### `/material drag <nombre>`

Lista reordenable con CDK Drag and Drop:
```html
<div cdkDropList (cdkDropListDropped)="drop($event)" class="flex flex-col gap-2">
  <div *ngFor="let item of items" cdkDrag
       class="flex items-center gap-3 p-3 bg-white rounded-lg shadow cursor-move border">
    <mat-icon cdkDragHandle class="text-gray-400">drag_indicator</mat-icon>
    <span>{{ item.nombre }}</span>
  </div>
</div>
```

```typescript
import { moveItemInArray, CdkDragDrop } from '@angular/cdk/drag-drop';

drop(event: CdkDragDrop<any[]>) {
  moveItemInArray(this.items, event.previousIndex, event.currentIndex);
}
```

### Imports por versión

**Material 15+ standalone:**
```typescript
imports: [
  MatTableModule, MatPaginatorModule, MatSortModule,
  MatFormFieldModule, MatInputModule, MatButtonModule,
  MatIconModule, MatDialogModule, MatSnackBarModule,
  MatSelectModule, MatDatepickerModule, MatNativeDateModule,
  MatChipsModule, MatAutocompleteModule, MatStepperModule,
  MatTabsModule, MatSidenavModule, MatToolbarModule,
  MatCardModule, MatMenuModule, MatCheckboxModule,
  MatTooltipModule, MatProgressSpinnerModule,
  DragDropModule,
]
```

**Material < 15 (NgModule):**
Mismos módulos pero declarados en el `imports: []` del NgModule compartido (SharedModule).
