# Changelog

Cambios relevantes de LexiEC. El formato sigue la idea de [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [Sin publicar]

### Añadido

- Proyecto Flutter base `lexiec` en `mobile/` (solo Android, identificador `com.katarisoft.lexiec`).
- Proyecto Django 5.2 LTS base en `backend/`, configurado por variables de entorno y con PostgreSQL.
- `backend/requirements.txt` con versiones fijadas y `backend/.env.example` sin valores secretos.
- Registro de versiones, decisiones y comandos de arranque en `docs/ESTADO.md`.
- Resumen de alcance, exclusiones y política de fuentes en `docs/ALCANCE.md`.
- Workflows de CI separados para la app (`ci-mobile.yml`) y el backend (`ci-backend.yml`, con PostgreSQL 16 efímero).
- Pruebas del backend sobre la conexión a PostgreSQL, las variables de entorno y el arranque sin `SECRET_KEY`.
- Pantalla provisional de la app con el aviso académico y su prueba de widget.

- App `library` con `LegalArea`, `SourceDocument`, `SourceFragment` y `TopicCard`, migración inicial y administración en Django Admin.
- Estados independientes de revisión humana, publicación y vigencia, con restricciones en base de datos y consultas `published()` y `eligible_for_assistant()`.

- Inventario auditable de 8 documentos oficiales candidatos en `docs/FUENTES.md` (URL, edición declarada, fecha de consulta, SHA-256, limitaciones y bloqueos) y prueba acotada de la API de GOB.EC.
- Plantilla de revisión para Revisor Jurídico en `docs/REVISION_JURIDICA.md`, sin aprobaciones registradas.

- Propuesta de 7 temas de Derecho de Familia, más 2 alternativas, con localizadores y páginas de las copias de trabajo, pendiente de aprobación (`docs/FUENTES.md`, sección 7).
- Propuesta de 7 temas de Derecho Laboral, más 2 alternativas, con localizadores y páginas en dos copias del Código del Trabajo, pendiente de aprobación (`docs/FUENTES.md`, sección 8).
- Propuesta de 7 temas de Derecho Constitucional y Participación Ciudadana, más 2 alternativas, con localizadores en la Constitución, la LOGJCC, la LOTAIP 2023, la LOPC y la LOCPCCS, pendiente de aprobación (`docs/FUENTES.md`, sección 9).
- App `accounts`: registro por correo, login JWT, renovación con rotación, perfil `me` y logout con lista negra del refresh (`/api/v1/auth/`).
- Django REST Framework 3.18.3 y SimpleJWT 5.5.1 como dependencias del backend.
- API de biblioteca: `GET /api/v1/areas/`, `GET /api/v1/topics/` (filtro por área, búsqueda y paginación) y `GET /api/v1/topics/{id}/` con fuentes publicadas, solo con sesión.
- Formato común de errores con códigos estables para 400, 401, 403, 404, 405, 415, 422, 429 y 500, documentado en `docs/API.md`.
- App `community`: comentarios públicos en fichas publicadas con listado paginado, creación, edición y borrado solo por el autor, y moderación en Django Admin.
- Perfil de cuenta con alias público opcional (`display_name`) en el registro y en `PATCH /api/v1/auth/me/`.
- Núcleo móvil: configuración de `API_BASE_URL`, cliente Dio con renovación única de sesión ante 401, errores tipados según `docs/API.md`, tokens en almacenamiento seguro, repositorio y `AuthController` (GetX).
- Dependencias móviles: get 4.7.3, dio 5.11.1 y flutter_secure_storage 11.2.0.
- Tema, rutas con protección de sesión, `InitialBinding` y pantallas de arranque, login, registro e inicio protegido con cierre de sesión.
- Biblioteca móvil: áreas en el inicio, listado por área o global con búsqueda explícita y «Cargar más», y detalle con fuentes (institución, documento, localizador, fechas, vigencia y limitaciones) y apertura segura del enlace oficial (url_launcher 6.3.3).
- Componentes reutilizables de carga, vacío y error con reintento.
- Comando de desarrollo `seed_demo_library` para datos ficticios rotulados (solo con DEBUG).
- Comentarios en el detalle de ficha: listado con recarga explícita y «Ver más», publicación con progreso y sin duplicados, conservación del texto si falla, edición en diálogo y borrado con confirmación; acciones visibles solo en comentarios propios.
- Favoritos y notas locales con Hive (hive_ce), separados por cuenta, persistentes tras reiniciar y disponibles sin conexión como copia guardada con fecha; borrado explícito de los datos locales de la cuenta.
- App `assistant`: `Consultation` y `ConsultationCitation`, historial privado (`GET`/`DELETE /api/v1/consultations/`) filtrado por propietario, y servicio de registro idempotente que valida las citas sin depender del proveedor de IA.
- Recuperación de fragmentos para el asistente: área obligatoria, solo contenido revisado y publicado, búsqueda de texto completo en español sin tildes, términos controlados, cobertura mínima configurable y contexto acotado; abstención sin llamar al proveedor (`docs/RECUPERACION.md`).
- Control de presupuesto de IA: registro `AIUsage` sin texto de consultas, reserva del coste máximo antes de cada llamada con bloqueo de PostgreSQL, conciliación, estado incierto que sigue contando, liberación solo si no se envió, límite diario por cuenta y comando `ai_budget` (`docs/PRESUPUESTO.md`).
- Adaptador de Claude (`anthropic` 1.15.0, sin reintentos ni herramientas) con documentos citables, abstención con marcador, rechazo de afirmaciones sin citas o con citas inválidas, y clasificación de errores para el presupuesto.
- `POST /api/v1/consultations/`: consulta completa con recuperación, presupuesto, idempotencia (también concurrente) y errores 409, 422, 429 y 503.
- Asistente en la app: área, aviso previo sobre datos personales, envío solo explícito, respuesta con fuentes oficiales citadas, estados distintos para «sin respaldo» y error técnico, reintento consciente con el mismo `client_request_id`, e historial privado con detalle y borrado confirmado.
- Despliegue con Docker: `backend/Dockerfile` (gunicorn 26.2.0, whitenoise 6.12.0, usuario sin privilegios), `infra/docker-compose.prod.yml` con PostgreSQL privado y backend solo en `127.0.0.1`, plantilla `infra/.env.production.example` sin secretos, ejemplo de Nginx y plan en `docs/DESPLIEGUE.md`.
- `GET /api/v1/health/`: comprobación pública y mínima; 503 sin detalles si la base no responde.

### Cambiado

- El backend carga `backend/.env` con `python-dotenv` 1.2.4, sin sobrescribir variables del entorno.
- Sustituido el contador de la plantilla de Flutter por la pantalla provisional de LexiEC.

### Eliminado

- `workflows/ci.yml`, que no estaba activo, sustituido por los workflows de `.github/workflows/`.

### Corregido

- `GET /api/v1/areas/` devolvía las áreas sin orden garantizado: Django no aplica `Meta.ordering` con `GROUP BY`; ahora se ordena explícitamente por `order` y `name`.
- `AuthController` ya no falla al reintentar tras un error sin errores por campo (mapa constante adoptado por `RxMap.assignAll`).

### Seguridad

- Producción detrás de proxy HTTPS (`DJANGO_BEHIND_HTTPS_PROXY`): cookies seguras, HSTS inicial de 1 hora, `nosniff`, `CSRF_TRUSTED_ORIGINS` configurable y registros sin cuerpos de peticiones.
- Interruptor `ASSISTANT_LIVE_CALLS`, desactivado por defecto: ninguna llamada real al proveedor sin activarlo expresamente.
- La clave de Anthropic solo se lee del entorno del servidor; sin ella el asistente responde 503 y nunca usa respuestas simuladas.
- El presupuesto de IA falla de forma cerrada si faltan tarifas o la configuración es incoherente; corte operativo de USD 8 sobre USD 10.
- Las consultas de otras cuentas responden 404 (no revelan su existencia); el borrado elimina la pregunta, la respuesta y las citas.
- HTTP sin cifrar permitido solo en el manifiesto de depuración de Android; el release exige HTTPS. Permiso `INTERNET` declarado en el manifiesto principal.
- Permisos por objeto en comentarios; autor y ficha asignados en el servidor; el correo de las cuentas no se expone a otras cuentas.

- Límite de intentos (429) en login y registro, configurable con `API_THROTTLE_LOGIN` y `API_THROTTLE_REGISTER`.
- Errores 404 y 500 de la API en JSON sin trazas ni detalles internos.

- Identificadas compilaciones de Ediciones Legales con «Prohibida su reproducción parcial o total» y de Lexis en dominios oficiales; su texto no se copiará a la base de datos sin decisión de Revisor Jurídico.

- `.gitignore` ampliado para excluir `.env.*` (excepto `.env.example`), claves de firma, entornos virtuales y bases SQLite.
- Eliminada la `SECRET_KEY` insegura que genera la plantilla de Django.
