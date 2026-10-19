# API de LexiEC — v1

Estado: implementado en el backend hasta E08 (autenticación, biblioteca y comentarios). Consultas e historial se documentarán en sus entregas.

- **Base:** `/api/v1/`.
- **Formato:** JSON en peticiones y respuestas. Otros tipos de contenido reciben 415.
- **Autenticación:** cabecera `Authorization: Bearer <access>`. Salvo que se indique lo contrario, todos los endpoints la exigen.

## 1. Formato común de errores

```json
{
  "error": {
    "code": "validation_error",
    "message": "La solicitud contiene datos inválidos.",
    "details": {"email": ["Introduzca una dirección de correo electrónico válida."]}
  }
}
```

- `code` es estable y está pensado para el cliente; `message` es un texto en español para mostrar.
- `details` es opcional: errores por campo en el 400 de validación y `retry_after_seconds` en el 429.
- Las respuestas de error nunca incluyen trazas, configuración ni datos internos.

| HTTP | `code` | Cuándo | Acción esperada del cliente |
|---|---|---|---|
| 400 | `validation_error` | Campos o parámetros mal formados (con `details` por campo) | Mostrar los errores junto al campo y conservar la entrada |
| 400 | `parse_error` | El cuerpo no es JSON válido | Error de programación del cliente |
| 400 | `invalid_refresh_token` | Logout con un refresh inválido, ya invalidado o de otra cuenta | Limpiar la sesión local |
| 401 | `not_authenticated` | Falta la cabecera `Authorization` | Ir a login |
| 401 | `token_not_valid` | Access o refresh inválido, caducado o en lista negra | Renovar una vez; si falla, limpiar la sesión e ir a login |
| 401 | `no_active_account` | Login con credenciales incorrectas o cuenta inactiva | Mensaje genérico; no revela si el correo existe |
| 403 | `permission_denied` | Autenticado, pero sin permiso sobre el recurso | Explicar la falta de permiso; no reintentar |
| 404 | `not_found` | El recurso no existe, no está publicado o la página está fuera de rango | «Contenido no disponible» |
| 405 | `method_not_allowed` | Método HTTP no admitido | Error de programación del cliente |
| 415 | `unsupported_media_type` | El cuerpo no es `application/json` | Error de programación del cliente |
| 422 | `unknown_area` | Petición bien formada que hace referencia a un área inexistente | Explicar y ofrecer las áreas válidas |
| 429 | `throttled` | Límite de intentos superado (cabecera `Retry-After` y `details.retry_after_seconds`) | Informar y permitir reintentar después |
| 500 | `server_error` | Error interno no controlado | Error temporal; reintento manual |

**Criterio 400 / 422:** el 400 corresponde a datos mal formados (tipo, longitud, formato). El 422 se reserva para validaciones semánticas definidas explícitamente sobre datos bien formados; en E07, solo `unknown_area`. No todo el 400 de DRF se convierte en 422.

## 2. Autenticación (`/api/v1/auth/`)

| Método y ruta | Auth | Petición | Respuesta correcta | Límite |
|---|---|---|---|---|
| `POST register/` | No | `{"email": "...", "password": "...", "display_name"?: "..."}` | 201 `{"id", "email", "display_name", "date_joined"}` | 5/hora por IP (`API_THROTTLE_REGISTER`) |
| `POST token/` | No | `{"email": "...", "password": "..."}` | 200 `{"access", "refresh"}` | 10/min por IP (`API_THROTTLE_LOGIN`) |
| `POST token/refresh/` | No | `{"refresh": "..."}` | 200 `{"access", "refresh"}`; el refresh anterior queda invalidado | — |
| `POST logout/` | Sí | `{"refresh": "..."}` | 204 sin cuerpo | — |
| `GET me/` | Sí | — | 200 `{"id", "email", "display_name", "date_joined"}` | — |
| `PATCH me/` | Sí | `{"display_name": "..."}` | 200 con el perfil actualizado. Ignora el correo y los campos de privilegio | — |

- **Vigencia de los tokens:** el access dura 15 min y el refresh 7 días, con rotación.
- **Logout:** invalida el refresh, pero el access ya emitido sigue siendo válido hasta caducar. El cliente debe descartar ambos.
- **Normalización del correo:** se guarda sin espacios y en minúsculas.
- **Contraseña:** se validan la longitud mínima, las contraseñas comunes, las solo numéricas y la similitud con el correo.
- **`display_name`:** alias público opcional de hasta 40 caracteres, sin «@». Es lo único que ven otras cuentas; si está vacío, se muestra «Usuario N». El correo nunca se expone a otras cuentas.

## 3. Biblioteca (requiere sesión)

### `GET areas/`

Lista sin paginar, ordenada por `order` y `name`.

```json
[{"id": 1, "slug": "familia", "name": "Derecho de Familia", "description": "", "order": 1, "published_topics": 7}]
```

`published_topics` cuenta solo las fichas aprobadas y publicadas.

### `GET topics/?area=<slug>&search=<texto>&page=<n>`

Solo fichas aprobadas y publicadas, ordenadas por el orden del área y el título.

| Parámetro | Validación | Error |
|---|---|---|
| `area` | slug, máx. 64 | 400 si está mal formado; 422 `unknown_area` si no existe |
| `search` | texto, máx. 100 | 400 si es demasiado largo |
| `page` | entero ≥ 1 | 400 si está mal formado; 404 si está fuera de rango |

`search` busca, sin distinguir mayúsculas, en el título, la explicación y los términos de búsqueda. Sí distingue tildes: «pension» no encuentra «pensión»; ver limitaciones.

```json
{
  "count": 21, "next": "…?page=2", "previous": null,
  "results": [
    {"id": 3, "slug": "…", "title": "…", "area": {"slug": "familia", "name": "Derecho de Familia"}, "summary": "…"}
  ]
}
```

Página de 20 elementos.

### `GET topics/{id}/`

404 `not_found` si la ficha no existe, es un borrador o no está aprobada.

```json
{
  "id": 3, "slug": "…", "title": "…",
  "area": {"slug": "…", "name": "…"},
  "summary": "…", "search_terms": ["…"],
  "reviewed_at": "2026-…", "updated_at": "2026-…",
  "sources": [
    {
      "id": 10, "locator": "Art. …", "text": "…", "reviewed_at": "2026-…",
      "document": {
        "id": 4, "title": "…", "institution": "…", "official_url": "https://…",
        "publication_reference": "…", "publication_date": "2008-10-20",
        "version_label": "…", "retrieved_at": "2026-10-16", "reviewed_at": "2026-…",
        "validity_status": "not_verified", "validity_status_label": "Vigencia no comprobada",
        "validity_checked_at": null, "limitations": "…"
      }
    }
  ]
}
```

- `sources` incluye solo fragmentos aprobados de documentos aprobados y publicados: el mismo criterio que alimenta al asistente.
- No se expone la identidad de quien revisó, solo las fechas.

## 4. Comentarios (requiere sesión)

Opiniones de la comunidad sobre fichas publicadas. **No son fuente normativa** ni alimentan al asistente.

| Método y ruta | Quién | Petición | Respuesta |
|---|---|---|---|
| `GET topics/{id}/comments/?page=<n>` | Cualquier sesión | — | 200 paginado (20), del más reciente al más antiguo; 404 si la ficha no está publicada |
| `POST topics/{id}/comments/` | Cualquier sesión | `{"text": "..."}` | 201 con el comentario; 400 si el texto está vacío o supera 1000 caracteres; 404 si la ficha no está publicada |
| `GET comments/{id}/` | Cualquier sesión | — | 200; 404 si no existe o su ficha no está publicada |
| `PATCH comments/{id}/` | Solo el autor | `{"text": "..."}` | 200; 403 `permission_denied` para otras cuentas |
| `DELETE comments/{id}/` | Solo el autor | — | 204; 403 `permission_denied` para otras cuentas |

```json
{"id": 7, "text": "…", "author": {"display_name": "Ana"}, "is_mine": false,
 "created_at": "2026-…", "updated_at": "2026-…", "edited": false}
```

- **Asignación en el servidor:** el autor y la ficha los asigna el servidor; los campos `author`, `topic` o similares enviados por el cliente se ignoran.
- **Permisos:** el permiso de edición y borrado se comprueba por objeto en el backend. `is_mine` solo sirve para la interfaz.
- **Métodos:** `PUT` no está admitido (405).
- **Moderación:** en Django Admin, donde se pueden consultar y eliminar comentarios y moderar alias. Las cuentas staff no tienen permisos especiales en la API.
- **Sin tiempo real:** los cambios se ven al recargar.

## 5. Limitaciones conocidas

- Búsqueda sensible a tildes. Se evaluará en E14 (recuperación) sin añadir infraestructura.
- Los límites de intentos usan la caché local por proceso. Con varios procesos o servidores, el límite efectivo se multiplica.
- Si una ficha publicada tiene fragmentos pendientes, estos no aparecen en `sources`. Una ficha puede quedar sin fuentes visibles: la app debe advertirlo.
