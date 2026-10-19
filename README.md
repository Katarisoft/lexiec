# LexiEC

Consulta documental jurídica ecuatoriana con fuentes oficiales y asistencia de IA, dirigida a ciudadanos sin formación jurídica.

El proyecto organiza contenido de Derecho de Familia, Derecho Laboral y Derecho Constitucional y Participación Ciudadana. Las respuestas del asistente deben limitarse a la colección revisada, mostrar referencias verificables y abstenerse cuando no exista respaldo suficiente.

> Proyecto académico. No sustituye asesoría profesional ni garantiza una interpretación correcta o actualización normativa completa. No introduzcas nombres, números de identificación, expedientes ni otros datos personales en las consultas.

## Estado del proyecto

Este README está adaptado al alcance acordado, pero no certifica que la implementación esté terminada. Las casillas permanecen pendientes hasta contar con evidencia real. Antes de la entrega deben reemplazarse los campos `PENDIENTE` y comprobarse los comandos contra el repositorio.

- Versión: PENDIENTE.
- Estado de implementación (2026-10-16): base del monorepositorio (E01, aceptada), CI mínima con pruebas iniciales (E02, aceptada) esquema documental con Django Admin (E03, aceptada), inventario y propuesta de 21 temas pendientes de revisión jurídica (E04) autenticación JWT en el backend (E06, aceptada) API de biblioteca con contrato de errores (E07, aceptada) comentarios con permisos por objeto (E08, aceptada) núcleo móvil de red y sesión (E09a, aceptada) pantallas de autenticación (E09b, aceptada) biblioteca móvil con fuentes (E10, aceptada; probada con datos DEMO ficticios porque la colección real depende de la revisión jurídica) comentarios móviles con prueba A/B en dispositivo (E11, aceptada) favoritos y notas locales por cuenta (E12, aceptada) historial privado de consultas en el backend (E13, aceptada) y recuperación documental sin proveedor (E14, pendiente de revisión; evaluación real pendiente de la colección revisada). Ninguna funcionalidad de la lista siguiente está completa todavía. Detalle por entrega en [docs/ESTADO.md](docs/ESTADO.md).
- Repositorio privado: PENDIENTE; el repositorio local aún no tiene remoto configurado, por lo que tampoco se ha comprobado el acceso del docente.
- Backend público HTTPS: PENDIENTE de configurar/documentar.
- Última revisión jurídica de la colección: PENDIENTE.

## Capturas de pantalla

Agregar al menos tres capturas reales en `docs/capturas/`: biblioteca principal, inicio de sesión y respuesta de IA con sus referencias. Recomendadas también: detalle de ficha, comentarios y favoritos.

PENDIENTE: insertar imágenes únicamente cuando los archivos existan. No utilizar capturas ficticias ni mostrar datos personales, tokens o credenciales.

## Funcionalidades y verificación

- [ ] Registro, inicio y cierre de sesión con Django y JWT.
- [ ] Tres áreas jurídicas y 21 fichas en PostgreSQL, siete por área.
- [ ] Fuentes y fragmentos oficiales con versión, localizador y revisión identificados.
- [ ] Estados de carga, vacío y error en pantallas con datos.
- [ ] Favoritos y notas locales que sobreviven al reinicio, separados por cuenta.
- [ ] Comentarios compartidos con creación, consulta, edición y eliminación protegidas.
- [ ] Historial privado de consultas con eliminación.
- [ ] Asistente a través de Django, con citas o abstención.
- [ ] Estado compartido mediante GetX.
- [ ] Pruebas, CI y APK instalable generado por GitHub Actions.

Estas casillas representan verificación pendiente, no una declaración de funcionalidades ya terminadas.

## Alcance y límites

### Incluido

Biblioteca delimitada de temas jurídicos, preguntas sobre la colección publicada y revisada, comentarios públicos por ficha, historial privado y almacenamiento local de favoritos/notas.

### No incluido

Asesoría personalizada, expedientes, carga de documentos personales, generación de escritos judiciales, chat entre usuarios, mapas, notificaciones y búsqueda autónoma de la IA en toda la web.

La ausencia de respuesta no significa que no exista una norma aplicable: puede indicar que el contenido está fuera de la colección disponible. Un fallo técnico debe mostrarse por separado de la falta de respaldo documental.

## Requisitos

Registrar las versiones realmente utilizadas; no actualizar SDKs solo para completar esta tabla.

Versiones del entorno de desarrollo registradas el 2026-10-16 (ver [docs/ESTADO.md](docs/ESTADO.md)):

| Herramienta | Versión comprobada |
|---|---|
| Flutter | 3.44.0, canal stable |
| Dart | 3.12.0 |
| Python | 3.12.3, con entorno virtual en `backend/.venv` |
| Django / Django REST Framework | Django 5.2.18 (LTS) / DRF 3.18.3; SimpleJWT 5.5.1 |
| PostgreSQL | 16.15 en local; `postgres:16` en CI |
| Docker / Docker Compose | 29.1.3 / 2.40.3 instalados; PENDIENTE: el proyecto aún no los usa |
| Entorno Android y emulador | Android SDK 36.1.0 y Gradle 9.1.0 (wrapper); PENDIENTE: ejecución en emulador no comprobada |

Además:
- Acceso al repositorio privado.
- Acceso a Claude API para la funcionalidad real de IA; Claude Pro para desarrollo no debe confundirse con la configuración de API del backend.
- Variables del servidor configuradas localmente por el propietario, nunca publicadas.

## Organización del repositorio

Estructura actual (2026-10-16):

```text
mobile/                 aplicación Flutter (Android, com.katarisoft.lexiec)
backend/                proyecto Django (config/), apps/accounts, apps/library, apps/community y tests/
.github/workflows/      CI: ci-mobile.yml y ci-backend.yml
workflows/              release-apk.yml, inactivo hasta la entrega de Release
docs/                   alcance, estado y notas de cambios por entrega
AGENTS.md               reglas para agentes de código
CLAUDE.md               instrucciones de trabajo para Claude Code
CHANGELOG.md            cambios por versión
GUIA_MAESTRA.md         guía de desarrollo por entregas
```

PENDIENTE: `infra/` (contenedores y despliegue), la parte de IA de la app `assistant` (recuperación, presupuesto y proveedor), y la publicación del APK en `.github/workflows/`.

## Configuración

El backend lee su configuración de variables de entorno. Si existe `backend/.env`, Django lo carga con `python-dotenv` sin sobrescribir las variables ya definidas en el proceso; `DJANGO_ENV_FILE` permite indicar otra ruta. El ejemplo sin secretos es [backend/.env.example](backend/.env.example): cada persona lo copia a `backend/.env` y rellena sus propios valores. `.env` y sus variantes están en `.gitignore`.

Variables implementadas (leídas por `backend/config/settings.py`):

| Variable | Ubicación | Finalidad |
|---|---|---|
| `DJANGO_DEBUG` | Servidor | `1` solo en desarrollo; desactivado por defecto. |
| `DJANGO_SECRET_KEY` | Solo servidor | Obligatoria con `DJANGO_DEBUG=0`; sin ella, el arranque falla. En depuración se genera una clave efímera. |
| `DJANGO_ALLOWED_HOSTS` | Servidor | Hosts permitidos, separados por comas. |
| `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT` | Solo servidor | Conexión PostgreSQL (por defecto `lexiec`, `localhost`, `5432`). Si la contraseña está vacía, libpq puede tomarla de `~/.pgpass`. |
| `DJANGO_ENV_FILE` | Servidor | Ruta alternativa del archivo de variables (opcional). |
| `API_THROTTLE_LOGIN`, `API_THROTTLE_REGISTER` | Servidor | Límites de intentos por IP (por defecto `10/min` y `5/hour`). |
| `ASSISTANT_MIN_COVERAGE` | Servidor | Cobertura mínima de palabras clave para considerar respaldo (por defecto `0.5`, provisional; ver `docs/RECUPERACION.md`). |

Variables propuestas, todavía no implementadas:

| Variable propuesta | Ubicación | Finalidad |
|---|---|---|
| `ANTHROPIC_API_KEY` | Solo servidor | Acceso al proveedor de IA. |
| `ANTHROPIC_MODEL` | Servidor | Modelo compatible elegido. |
| `AI_BUDGET_USD` | Servidor | Presupuesto global configurado. |
| `AI_OPERATING_LIMIT_USD` | Servidor | Corte conservador antes del límite global. |
| `API_BASE_URL` | Flutter, configuración pública | URL de Django; no es una credencial. |

PENDIENTE: variables de producción y quién configura los valores en el VPS. No adjuntar `.env`, claves de firma Android ni contraseñas al repositorio.

## Cómo ejecutar el proyecto

### 1. Obtener el código

PENDIENTE: reemplazar el identificador del repositorio privado por su URL real.

```bash
git clone <URL_REAL_DEL_REPOSITORIO_PRIVADO>
cd <CARPETA_REAL_DEL_REPOSITORIO>
```

### 2. Backend y PostgreSQL

Este apartado debe contener comandos exactos ya comprobados. No se incluyen nombres ficticios de servicios o comandos de importación como si estuvieran implementados.

Ejecución local sin Docker, comprobada el 2026-10-16 en Ubuntu 24.04 con Python 3.12 y PostgreSQL 16:

```bash
virtualenv backend/.venv
backend/.venv/bin/pip install -r backend/requirements.txt
cp backend/.env.example backend/.env  # rellenar valores propios; no versionar
cd backend
.venv/bin/python manage.py check
.venv/bin/python manage.py makemigrations --check --dry-run
.venv/bin/python manage.py migrate
```

`migrate` se comprobó el 2026-10-16 sobre una base local vacía `lexiec`. El contenido documental se gestiona en Django Admin (`/admin/`): áreas, documentos fuente, fragmentos y fichas, cada uno con estado de revisión, publicación y, en documentos, vigencia. La cuenta administrativa la crea cada persona con `manage.py createsuperuser`; no se publican credenciales.

Las pruebas necesitan un rol de PostgreSQL con permiso `CREATEDB`: Django crea y borra la base temporal `test_<POSTGRES_DB>`.

PENDIENTE de documentar y verificar:
1. Archivo Compose utilizado y nombre real del servicio Django.
2. Configuración de variables de producción sin secretos.
3. Comando para construir y levantar los contenedores.
4. Comando de migraciones dentro de contenedores (en local sin Docker: `manage.py migrate`, ver arriba).
5. Comando idempotente para cargar las 21 fichas revisadas.
6. Creación local de cuenta administrativa por el propietario, sin publicar credenciales.
7. Endpoint de salud y resultado esperado.
8. Comandos para detener servicios sin eliminar volúmenes.

No usar la base de producción para pruebas ni ejecutar borrado de volúmenes como paso normal de arranque.

### 3. Aplicación Flutter

Estado actual: registro, login, sesión persistente, cierre de sesión y biblioteca (áreas, fichas, búsqueda y detalle con fuentes) contra el backend.

Datos de demostración **ficticios** para probar la biblioteca en desarrollo (no es legislación; solo con `DJANGO_DEBUG=1`):

```bash
cd backend
.venv/bin/python manage.py seed_demo_library          # crear
.venv/bin/python manage.py seed_demo_library --clear  # eliminar (obligatorio antes de cargar la colección real)
```

Prueba en dispositivo físico por USB, comprobada el 2026-10-19 en un Pixel 9a (sin exponer el backend a la red local):

```bash
# Terminal 1: backend solo en localhost
cd backend && .venv/bin/python manage.py runserver 127.0.0.1:8000
# Terminal 2: túnel USB y app
adb reverse tcp:8000 tcp:8000
cd mobile
flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
# Al terminar
adb reverse --remove tcp:8000
```

El build de depuración permite HTTP sin cifrar solo para este uso local; el de release exige HTTPS.

Ejecución con `flutter run` (variable de configuración real: `API_BASE_URL`):

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=<URL_BASE_REAL_DEL_BACKEND>
```

`API_BASE_URL` es la raíz del servidor, sin `/api/v1/`. La app añade el prefijo y, si se incluye por error, lo normaliza sin duplicarlo (probado en `test/core/app_config_test.dart`). Valor por defecto: `http://10.0.2.2:8000` (emulador Android). Entornos probados: dispositivo físico por túnel USB (E09b). No permitir HTTP sin cifrar en builds de producción; si el desarrollo local lo necesita, limitarlo a una configuración de depuración explícita.

### 4. Direcciones por entorno

| Entorno | Dirección comprobada e instrucciones |
|---|---|
| Emulador Android | `http://10.0.2.2:8000` (valor por defecto). PENDIENTE: no comprobado; el propietario usa dispositivo físico. |
| Dispositivo físico | Comprobado por USB con `adb reverse` y `API_BASE_URL=http://127.0.0.1:8000` (ver arriba). Por red local: PENDIENTE. |
| VPS / APK de evaluación | PENDIENTE: URL HTTPS y disponibilidad durante la evaluación. |

No asumir que `localhost` en el teléfono es el computador del desarrollador. Documentar la conexión realmente utilizada.

### 5. IA real y pruebas sin coste

- El servicio real de IA requiere configuración del proveedor en Django.
- Los dobles de proveedor solo se utilizan en pruebas explícitas.
- No existe un fallback silencioso a respuestas simuladas en la aplicación real.
- Sin credenciales, saldo o disponibilidad, mostrar un error técnico claro y mantener el resto de la app operativo.
- PENDIENTE: comandos reales para ejecutar pruebas sin llamadas de pago.

## Recorrido para evaluar la aplicación

1. Registrar dos cuentas de prueba A y B, sin privilegios administrativos.
2. Abrir la biblioteca, recorrer las tres áreas y verificar las fichas.
3. Abrir una ficha y consultar documento, localizador y enlace oficial.
4. Publicar un comentario con A y comprobar que B lo ve al actualizar.
5. Confirmar que B no puede editar ni eliminar el comentario de A.
6. Guardar un favorito y una nota; cerrar por completo y abrir de nuevo.
7. Cambiar de cuenta y comprobar que los datos locales no se mezclan.
8. Formular una pregunta cubierta por la colección y revisar sus referencias.
9. Formular otra fuera de alcance y comprobar la abstención.
10. Revisar y eliminar una consulta del historial privado.
11. Cerrar sesión y comprobar el rechazo de operaciones protegidas.

PENDIENTE: añadir preguntas de evaluación concretas aprobadas por la persona revisora. No inventar respuestas esperadas ni consumir API automáticamente durante este recorrido.

## Fuentes y revisión jurídica

La colección se almacena en PostgreSQL. No son listas de negocio escritas directamente en pantallas Flutter.

Objetivo inicial: 21 fichas, siete por área, respaldadas por documentos oficiales ecuatorianos y fragmentos con contexto suficiente.

Fuentes candidatas, no una afirmación de que ya hayan sido incorporadas:
- Registro Oficial.
- Asamblea Nacional.
- Otros organismos oficiales competentes según el tema.
- GOB.EC como integración complementaria, condicionada a validar cobertura y disponibilidad.

Consultar `docs/FUENTES.md` y `docs/REVISION_JURIDICA.md` cuando existan. Deben registrar institución, URL, título, publicación conocida, versión, localizador, fecha de revisión, limitaciones y evidencia de aprobación.

Un documento oficial no acredita por sí solo que el texto esté consolidado y actualizado. Los documentos pendientes de revisión no deben alimentar el asistente. Los comentarios comunitarios nunca son fuentes normativas.

## Asistente y presupuesto

Flujo previsto:

```text
Pregunta y área
  → autenticación y validación
  → recuperación de fragmentos revisados
  → control de presupuesto y reserva
  → Claude desde Django
  → comprobación de referencias
  → respuesta o abstención
  → historial privado y conciliación de consumo
```

Presupuesto aprobado de API: hasta USD 10 para desarrollo y evaluación. Corte operativo inicial propuesto: USD 8, sujeto a configuración real. Esto no autoriza al agente a efectuar llamadas por iniciativa propia.

Controles previstos: límites de entrada/salida, cuotas por usuario, reservas concurrentes, conciliación del consumo y ausencia de reintentos de pago automáticos. El ledger interno estima consumo y debe contrastarse con la facturación del proveedor.

PENDIENTE: modelo, tarifas verificadas, cuotas finales y estado de implementación de los controles. No prometer un tope de factura garantizado solo por el ledger de la aplicación.

## APK y Release

PENDIENTE: versión publicada, enlace interno al Release, nombre del workflow y archivo APK real.

El APK de entrega debe generarse mediante GitHub Actions al subir una etiqueta autorizada y quedar adjunto al Release. El propietario hace commit, push y tag; el agente prepara los archivos e instrucciones.

Como el repositorio es privado, verificar que el docente tiene acceso al repositorio y su Release.

PENDIENTE de registrar:
- Etiqueta y commit del APK.
- Ejecución real de Actions y resultado.
- Emulador limpio donde se instaló.
- URL HTTPS usada por la app.
- Resultado del recorrido de evaluación.

La clave del proveedor de IA nunca se incorpora al APK ni a `--dart-define`.

## Arquitectura

```text
Flutter
  Pantalla
    → GetxController
      → Repositorio
        → Servicio HTTP / Hive / almacenamiento seguro
                   │
                   ▼
Django REST Framework
  API
    → Validación y permisos
      → Servicios
        → PostgreSQL / proveedor de IA
```

Las pantallas no hacen llamadas HTTP ni acceden directamente a Hive. GetX centraliza el estado compartido. Django impone autorización y limita la colección que puede utilizar el asistente.

PENDIENTE: ajustar el diagrama al código final y enlazar `docs/ARQUITECTURA.md` cuando exista.

## Decisión técnica propia

Decisión de diseño acordada: utilizar una colección delimitada y revisada en PostgreSQL antes que depender completamente de una API jurídica externa.

Motivo: controlar qué documentos respaldan las respuestas, registrar versiones y revisar la colección utilizada en evaluación. Una integración externa puede añadirse sin convertirla en requisito para usar la biblioteca inicial.

Alternativas no elegidas para el alcance inicial: consultas web abiertas de la IA, base vectorial independiente y cobertura de toda la normativa ecuatoriana.

Limitación: una colección pequeña no responde todas las preguntas; la abstención es parte del comportamiento esperado. La procedencia oficial tampoco elimina el riesgo de interpretación errónea.

## Tecnologías

Stack acordado; confirmar paquetes y versiones en los archivos de dependencias:

| Tecnología | Uso |
|---|---|
| Flutter / Dart | Aplicación Android. |
| GetX | Estado, rutas y dependencias según la implementación. |
| Dio | Acceso HTTP desde servicios. |
| Hive (hive_ce 2.22.0) | Favoritos y notas locales por cuenta, sin cifrar y sin tokens. |
| flutter_secure_storage | Almacenamiento de tokens. |
| Django / DRF | API, validaciones y permisos. |
| PostgreSQL | Datos persistentes y recuperación documental. |
| Claude API | Respuestas sobre fragmentos proporcionados desde Django. |
| Docker / Compose | Ejecución de backend y base de datos. |
| GitHub Actions | Verificación y generación del APK. |

## Seguridad y privacidad

Políticas previstas; verificar su implementación antes de marcarlas como cumplidas:
- [ ] Secretos fuera del repositorio y auditoría del historial realizada.
- [ ] Token móvil en almacenamiento seguro, nunca impreso.
- [ ] Clave de IA solo en servidor.
- [x] Historial filtrado por propietario y permisos por objeto probados (comentarios E08 y consultas E13, con usuarios A/B).
- [ ] Autor de comentarios asignado en servidor.
- [x] Favoritos/notas separados por cuenta; logout limpia memoria y cierra cajas (E12: pruebas con Hive real y verificación en dispositivo con dos cuentas).
- [x] Notas locales no se presentan como almacenamiento seguro de datos sensibles (aviso visible en la nota; Hive sin cifrar y sin tokens).
- [ ] Preguntas y respuestas privadas no se registran en logs operativos.
- [ ] Eliminación de consultas y política de retención de copias documentadas.
- [ ] PostgreSQL sin exposición pública y backend con HTTPS.
- [ ] Configuración de producción revisada: DEBUG desactivado y hosts limitados.

PENDIENTE: política real de backups, acceso, retención y eliminación. No afirmar que un borrado en la app elimina de inmediato todas las copias de respaldo.

## Pruebas y manejo de errores

Comandos reales del proyecto (los mismos que ejecuta la CI):

```bash
cd mobile
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

```bash
cd backend
.venv/bin/python manage.py check
.venv/bin/python manage.py makemigrations --check --dry-run
.venv/bin/python manage.py test --noinput
```

Resultados locales del 2026-10-19 (cambios de E14 sin commit, sin Docker):

| Comando | Resultado |
|---|---|
| `dart format` (comprobación) | Sin cambios |
| `flutter analyze` | Sin problemas |
| `flutter test` | 99 pruebas superadas (favoritos y notas: Hive real con reinicio y aislamiento por cuenta, cambio de cuenta en pantallas; comentarios: publicar, editar, borrar, A/B y conservación de texto; configuración; errores HTTP y de red; renovación única ante 401; autenticación; biblioteca: estados carga/vacío/error, búsqueda, paginación, detalle con fuentes y enlaces; regla de pantallas sin HTTP) |
| `manage.py check` | Sin problemas |
| `makemigrations --check --dry-run` | Sin cambios pendientes |
| `manage.py test --noinput` (PostgreSQL 16 local) | 137 pruebas superadas (recuperación: área obligatoria, tildes, raíces, términos controlados, abstención; historial privado A/B, validación de citas e idempotencia; configuración; biblioteca y Admin; autenticación JWT y perfil; API de biblioteca; contrato de errores 400–500 y límites 429; comentarios con permisos A/B, IDOR y moderación) |

CI en GitHub Actions: `.github/workflows/ci-mobile.yml` y `.github/workflows/ci-backend.yml`, este último con PostgreSQL 16 efímero. PENDIENTE: ejecución remota no confirmada, porque el repositorio aún no tiene remoto.

Si se usa Docker u otro ejecutor, sustituir estos comandos por los equivalentes verificados.

Contrato de errores y payloads del backend: [docs/API.md](docs/API.md).

Documentar en `docs/PRUEBAS.md` los casos de autenticación, autorización A/B, reinicio de favoritos, fuentes/citas, abstención, privacidad, presupuesto y errores.

| Condición | Comportamiento esperado |
|---|---|
| 400 | Solicitud inválida con explicación útil. |
| 401 | Renovación controlada o retorno a login. |
| 403 | Acción no autorizada. |
| 422 | Validación semántica explícita definida por la API (por ahora, `unknown_area`). |
| 429 | Límite alcanzado. |
| 5xx | Error temporal del servicio. |
| Sin red / timeout | Mensaje específico, sin envío de pago duplicado automático. |

PENDIENTE: pruebas de funcionalidades (autenticación, A/B, favoritos, citas, errores HTTP), CI remota e instalación del APK. No afirmar CI verde ni instalación correcta sin evidencia.

## Matriz de entrega académica

| Criterio | Peso | Evidencia a completar |
|---|---:|---|
| Persistencia remota o colaborativa | 20 % | Comentarios protegidos y cambios visibles entre cuentas. |
| Autenticación | 15 % | Registro/login/logout y rechazo sin credenciales. |
| Datos reales | 15 % | 21 fichas persistentes con fuentes. |
| Persistencia local | 10 % | Favoritos/notas después de cerrar la app. |
| Estado con GetX | 10 % | Controladores y estado compartido. |
| IA sin secretos | 10 % | Servidor intermedio y auditoría limpia. |
| Manejo de errores | 10 % | Carga/vacío/error y fallos provocados. |
| Arquitectura | 5 % | Separación entre pantallas, estado y servicios. |
| Documentación y entrega | 5 % | README reproducible, historial y APK de Actions. |

## Desarrollo por entregas

Leer `AGENTS.md`, `CLAUDE.md`, `GUIA_MAESTRA.md`, `docs/ALCANCE.md` y `docs/ESTADO.md`. Cada entrega debe contener:
1. Contexto: reglas y estado actual.
2. Objetivo: comportamiento nuevo.
3. Restricciones: qué no modificar.
4. Criterios de aceptación: pruebas y evidencia.

El agente prepara cambios pequeños, pruebas, nota y mensaje de commit. El propietario revisa y ejecuta commit/push. El changelog no debe afirmar versiones ni publicaciones inexistentes.

## Créditos y licencias

PENDIENTE de completar con material realmente utilizado:
- Autoría y responsable del proyecto.
- Inventario de fuentes oficiales, URLs, atribuciones y condiciones de reutilización.
- Paquetes y licencias verificadas según versiones instaladas.
- Iconos, tipografías e imágenes, si existen.
- Licencia elegida para el código del proyecto. Un repositorio privado no implica una licencia abierta.

No declarar que todo el contenido jurídico es libremente redistribuible sin comprobar las condiciones aplicables.

## Lista antes de entregar

- [ ] No quedan marcadores PENDIENTE que impidan ejecutar o evaluar.
- [ ] Funcionalidades verificadas y límites documentados.
- [ ] Colección revisada y fuentes identificadas.
- [ ] README seguido en entorno limpio.
- [ ] Pruebas y CI verificadas.
- [ ] Auditoría de secretos limpia.
- [ ] Backend disponible para evaluación.
- [ ] APK del Release instalado y recorrido completo comprobado.
- [ ] Acceso del docente al repositorio privado y Release confirmado.
- [ ] Enlace del repositorio enviado en Moodle antes del límite.
