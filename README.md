# appmantflutter

A new Flutter project.

## Parámetros Excel (Firestore only)

Este repo genera y visualiza parámetros desde Firestore. **No se usa Firebase Storage ni Microsoft Graph/OneDrive.**

### Flujo general
- Firestore (`productos`) es la fuente de verdad.
- Cloud Functions genera los **esquemas** (`parametros_schemas`) a partir de los templates `.xlsx` locales.
- Los datos para el visor se almacenan en `parametros_datasets`.
- La app Flutter muestra las tablas y genera el Excel localmente en el dispositivo.

## Endpoints HTTP (Functions 1st gen)

### Inicializar esquemas y datasets
Lee las plantillas en `functions/assets/excel_templates` y crea:
- `parametros_schemas/<disciplina>_<tipo>`
- `parametros_datasets/<disciplina>_<tipo>`

```bash
curl -X GET https://<region>-<project-id>.cloudfunctions.net/initParametrosSchemas
```

## Modelo de datos (Firestore)

### parametros_schemas
Doc ID: `<disciplina>_<tipo>` (ej: `electricas_base`)

```json
{
  "disciplina": "electricas",
  "tipo": "base",
  "filenameDefault": "Electricas_Base_ES.xlsx",
  "columns": [
    { "key": "id", "displayName": "id", "order": 0, "type": "text", "required": true },
    { "key": "nombre", "displayName": "Nombre", "order": 1, "type": "text", "required": true }
  ],
  "aliases": { "nivel": "piso" },
  "updatedAt": "<timestamp>"
}
```

### parametros_datasets
Doc ID: `<disciplina>_<tipo>` (ej: `electricas_base`)

```json
{
  "disciplina": "electricas",
  "tipo": "base",
  "columns": [ ... ],
  "rowsById": {
    "<id>": { "id": "<id>", "values": { "nombre": "..." }, "updatedAt": "<timestamp>" }
  },
  "rowCount": 12,
  "generatedAt": "<timestamp>",
  "storageMode": "document"
}
```

> Si el documento crece demasiado, se cambia automáticamente a `storageMode = "subcollection"` y las filas se almacenan en `parametros_datasets/<id>/rows/<rowId>`.

## Mapeo de columnas
- Se usa la fila 1 del template como headers.
- Si no existe una columna `id`, se agrega como primera columna.
- Para cada fila:
  - `id`: ID del documento de `productos`.
  - `nombre`: `doc.nombre`.
  - `piso`: `doc.piso` o fallback `doc.ubicacion.nivel` o `doc.nivel`.
  - `estado`: `doc.estado`.
  - Otras columnas: `doc.attrs[key]` → `doc[key]` → vacío.

## Viewer y generación local
La pantalla de Parámetros permite:
- Seleccionar disciplina.
- Ver tablas Base/Reportes.
- Generar el Excel localmente con el nombre `filenameDefault`.

## Despliegue
```bash
firebase deploy --only functions
```
