---
description: Asistente para ESLint, Prettier y TSLint — configura, corre, corrige reglas y mantiene código limpio en proyectos Angular, NestJS y Next.js
---

# linting

Asistente para linting y formateo de código. Detecta si el proyecto usa ESLint (moderno) o TSLint (legacy CORINSA/EMSULA) y genera configuración, corre el linter y sugiere fixes.

## Uso

```
/linting run                          → corre el linter en el proyecto activo
/linting fix                          → corre linter con --fix (autofix)
/linting config eslint                → genera configuración ESLint para el proyecto
/linting config prettier              → genera .prettierrc con las reglas del equipo
/linting config tslint                → revisa/actualiza TSLint (proyectos legacy)
/linting migrate                      → migra TSLint → ESLint (proyectos CORINSA/EMSULA)
/linting rule <nombre> <valor>        → agrega o cambia una regla específica
/linting ignore <patron>              → agrega patrón a .eslintignore
/linting precommit                    → configura Husky + lint-staged
```

## Framework por proyecto

| Alias | Linter | Formatter | Versión |
|---|---|---|---|
| bodega bo api, bodega services | ESLint 9.x | Prettier 3.x | Flat config |
| bodega ecommerce (Next.js) | ESLint 9.x | Prettier 3.x | Flat config |
| bodega bo (Angular 20) | Angular ESLint 20.x | Prettier 3.x | Flat config |
| nai inhands bo (Angular 21) | Angular ESLint | Prettier 3.x | Flat config |
| yalo agendo (Angular 21) | Angular ESLint | — | Flat config |
| ult bo / ult ecom (NX) | ESLint 8.x + NX plugin | Prettier 2.x | .eslintrc.json |
| corinsa bi fe (Angular 7) | TSLint 5.x | — | tslint.json |
| cpa fe (Angular 10) | TSLint 6.x | — | tslint.json |
| doctor fe (Angular 13) | TSLint 6.x | — | tslint.json |

---

## ESLint — Proyectos modernos

### `/linting config eslint` — NestJS (flat config `eslint.config.mjs`)

```javascript
// eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettierConfig from 'eslint-config-prettier';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  prettierConfig,  // desactiva reglas de formato que maneja Prettier
  {
    languageOptions: {
      parserOptions: {
        project:      './tsconfig.json',
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // TypeScript
      '@typescript-eslint/no-explicit-any':           'warn',
      '@typescript-eslint/no-floating-promises':      'error',
      '@typescript-eslint/no-unused-vars':            ['warn', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-function-return-type': 'off',

      // NestJS — permite decoradores con nombres en PascalCase
      '@typescript-eslint/no-extraneous-class':       'off',

      // General
      'no-console':                                   ['warn', { allow: ['warn', 'error'] }],
    },
    ignores: ['dist/', 'node_modules/', 'coverage/'],
  },
);
```

### `/linting config eslint` — Angular (flat config)

```javascript
// eslint.config.js
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import angular from 'angular-eslint';
import prettierConfig from 'eslint-config-prettier';

export default tseslint.config(
  {
    files: ['**/*.ts'],
    extends: [
      eslint.configs.recommended,
      ...tseslint.configs.recommended,
      ...angular.configs.tsRecommended,
      prettierConfig,
    ],
    processor: angular.processInlineTemplates,
    rules: {
      '@angular-eslint/directive-selector':  ['error', { type: 'attribute', prefix: 'app', style: 'camelCase' }],
      '@angular-eslint/component-selector':  ['error', { type: 'element',   prefix: 'app', style: 'kebab-case' }],
      '@typescript-eslint/no-explicit-any':  'warn',
      '@typescript-eslint/no-unused-vars':   ['warn', { argsIgnorePattern: '^_' }],
    },
  },
  {
    files: ['**/*.html'],
    extends: [...angular.configs.templateRecommended, ...angular.configs.templateAccessibility],
    rules: {},
  },
);
```

### `/linting config eslint` — Next.js

```javascript
// eslint.config.mjs
import { dirname } from 'path';
import { fileURLToPath } from 'url';
import { FlatCompat } from '@eslint/eslintrc';

const __dirname = dirname(fileURLToPath(import.meta.url));
const compat = new FlatCompat({ baseDirectory: __dirname });

export default [
  ...compat.extends('next/core-web-vitals', 'next/typescript'),
  {
    rules: {
      '@typescript-eslint/no-explicit-any':    'warn',
      '@typescript-eslint/no-unused-vars':     ['warn', { argsIgnorePattern: '^_' }],
      'react-hooks/exhaustive-deps':           'warn',
      'import/no-anonymous-default-export':    'off',
    },
    ignores: ['.next/', 'node_modules/'],
  },
];
```

---

## Prettier

### `/linting config prettier` — `.prettierrc`

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "overrides": [
    {
      "files": "*.html",
      "options": {
        "parser": "html",
        "printWidth": 120,
        "htmlWhitespaceSensitivity": "ignore"
      }
    }
  ]
}
```

```
# .prettierignore
dist/
.next/
node_modules/
coverage/
*.min.js
*.lock
```

---

## Comandos de linting por proyecto

### `/linting run` y `/linting fix`

```bash
# ESLint
npx eslint src/                      # solo mostrar errores
npx eslint src/ --fix                # corregir los auto-fixables
npx eslint src/ --format=compact     # output compacto

# ESLint en archivo específico
npx eslint src/app/mi-componente.ts

# Prettier
npx prettier --check src/            # verificar sin cambiar
npx prettier --write src/            # aplicar formato

# Prettier en archivo específico
npx prettier --write src/app/mi-componente.ts

# Angular (incluye ESLint + Prettier en algunos proyectos)
ng lint
ng lint --fix

# NX
nx lint <nombre-proyecto>
nx run-many --target=lint            # lintear todos los proyectos
```

---

## TSLint (proyectos legacy: CORINSA, EMSULA)

### Ver errores TSLint actuales

```bash
npx tslint --project tsconfig.json src/**/*.ts
```

### `/linting migrate` — Migrar TSLint → ESLint

Para proyectos legacy que aún usan TSLint:

```bash
# 1. Instalar herramienta de migración
npm install --save-dev tslint-to-eslint-config

# 2. Auto-convertir tslint.json → .eslintrc.json
npx tslint-to-eslint-config

# 3. Instalar las dependencias de ESLint generadas
npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin

# 4. Agregar script en package.json
"lint": "eslint --ext .ts src/"

# 5. Actualizar angular.json para usar ESLint
ng add @angular-eslint/schematics

# 6. Remover TSLint
npm uninstall tslint
```

⚠️ Revisar reglas migradas — algunas no tienen equivalente directo en ESLint.

---

## Husky + lint-staged (pre-commit)

### `/linting precommit`

```bash
# Instalar
npm install --save-dev husky lint-staged
npx husky init
```

```json
// package.json — agregar
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{html,scss,css,json,md}": [
      "prettier --write"
    ]
  }
}
```

```sh
# .husky/pre-commit
npx lint-staged
```

---

## Reglas más comunes que se desactivan

```javascript
// En rules: — casos donde la regla molesta más que ayuda
'@typescript-eslint/no-explicit-any':            'off',  // cuando hay interop con librerías
'@typescript-eslint/explicit-function-return-type': 'off', // inferencia de tipos
'@typescript-eslint/no-empty-function':          'off',  // constructores vacíos DI
'@typescript-eslint/no-non-null-assertion':      'off',  // cuando se sabe que no es null
'no-console':                                    'off',  // en desarrollo
```

## `/linting rule <nombre> <valor>`

Agrega o modifica una regla específica en `eslint.config.js/mjs`:

```javascript
// Ejemplo: cambiar 'no-explicit-any' de error a warn
'@typescript-eslint/no-explicit-any': 'warn',

// Ejemplo: desactivar regla para un archivo específico
{
  files: ['src/generated/**/*.ts'],
  rules: {
    '@typescript-eslint/no-explicit-any': 'off',
  },
}
```
