# Despliegue del backend de LexiEC

Plan de E20 (2026-10-19). **Probado solo en local con Docker**: no se ha ejecutado en el VPS ni se ha conectado nadie por SSH. Los pasos del VPS los ejecuta el propietario.

## Arquitectura

```text
App Android ──HTTPS──> Nginx del host (leixec.katarisoft.com, TLS)
                         └─> 127.0.0.1:8001 ─> contenedor backend (gunicorn, 3 workers, :8000)
                                                └─> red interna ─> contenedor db (postgres:16, sin puertos)
```

- **Nginx** es el que ya existe en el VPS. El ejemplo [infra/nginx/lexiec.conf.example](../infra/nginx/lexiec.conf.example) se adapta a mano, sin reemplazar la configuración actual.
- **Backend:** [backend/Dockerfile](../backend/Dockerfile) con Python 3.12, usuario sin privilegios (uid 10001), estáticos del Admin servidos por whitenoise y sin secretos en la imagen.
- **PostgreSQL:** sin puertos publicados y datos en el volumen `lexiec_pgdata`.
- **Compose:** [infra/docker-compose.prod.yml](../infra/docker-compose.prod.yml). Las migraciones **no** se ejecutan solas.

> **Dominio:** se usa `leixec.katarisoft.com`, tal como lo indicó el propietario. Si era `lexiec`, hay que corregirlo en `infra/.env.production`, en Nginx y en el certificado.

## 1. Preparar el entorno (una vez)

```bash
cp infra/.env.production.example infra/.env.production
chmod 600 infra/.env.production
# Rellenar DJANGO_SECRET_KEY y POSTGRES_PASSWORD con valores largos y aleatorios.
```

- `infra/.env.production` está ignorado por git. También puede guardarse fuera del repositorio; en ese caso se indica su ruta absoluta con `LEXIEC_ENV_FILE`.
- `ASSISTANT_LIVE_CALLS=0` y `ANTHROPIC_API_KEY` vacía: sin llamadas de pago hasta que el propietario autorice un lote ([PRESUPUESTO.md](PRESUPUESTO.md)).
- `DJANGO_BEHIND_HTTPS_PROXY=1` solo si Nginx termina HTTPS y envía `X-Forwarded-Proto`.

## 2. Construir y arrancar

```bash
docker compose -f infra/docker-compose.prod.yml up -d --build
docker compose -f infra/docker-compose.prod.yml ps        # db y backend «healthy»
```

## 3. Migraciones (explícitas)

```bash
docker compose -f infra/docker-compose.prod.yml run --rm backend python manage.py migrate --plan
# Antes de una migración en producción: copia de seguridad (sección 6).
docker compose -f infra/docker-compose.prod.yml run --rm backend python manage.py migrate
```

## 4. Cuenta administrativa y contenido

```bash
docker compose -f infra/docker-compose.prod.yml run --rm backend python manage.py createsuperuser
```

- La cuenta la crea el propietario de forma interactiva. Las credenciales no se registran en ningún archivo.
- **No hay datos DEMO en producción:** `seed_demo_library` exige `DJANGO_DEBUG=1`.
- **Carga de las 21 fichas: PENDIENTE (E05/E18).** Depende de la revisión jurídica. No existe todavía ningún comando de importación.

## 5. Nginx y comprobación

1. Copiar el bloque del ejemplo a la configuración del sitio y ajustar las rutas del certificado.
2. Ejecutar `sudo nginx -t` y, si es correcto, `sudo systemctl reload nginx`.
3. Comprobar el servicio:

```bash
curl -s https://leixec.katarisoft.com/api/v1/health/       # {"status":"ok"}
curl -s -o /dev/null -w '%{http_code}\n' https://leixec.katarisoft.com/api/v1/areas/   # 401 sin sesión
```

Si la base no responde, `/api/v1/health/` devuelve 503 sin detalles internos.

## 6. Copias de seguridad y restauración

**Copia:**

```bash
docker compose -f infra/docker-compose.prod.yml exec -T db \
  sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > lexiec_$(date +%F).dump
chmod 600 lexiec_*.dump
```

**Restauración de prueba en una base nueva**, sin tocar la real:

```bash
docker compose -f infra/docker-compose.prod.yml exec -T db \
  sh -c 'createdb -U "$POSTGRES_USER" lexiec_restore_test'
docker compose -f infra/docker-compose.prod.yml exec -T db \
  sh -c 'pg_restore -U "$POSTGRES_USER" -d lexiec_restore_test --no-owner' < lexiec_AAAA-MM-DD.dump
```

- Las copias contienen las consultas privadas de las cuentas. Deben guardarse fuera del repositorio, con permisos 600 y acceso solo del propietario.
- **Retención: PENDIENTE de decisión del propietario.** Propuesta: copia diaria y conservar 7 días.
- **Borrado:** una consulta borrada en la app desaparece de la base de inmediato, pero **sigue en las copias** hasta que estas caducan.

## 7. Registros

- **Rotación** con `json-file` de Docker: 10 MB × 5 archivos por contenedor.
- **Qué registra gunicorn:** método, ruta y estado.
- **Qué registra Django:** solo avisos y errores (`DJANGO_LOG_LEVEL=WARNING`).
- **Qué no registra:** los cuerpos de las peticiones (preguntas y respuestas) ni el texto de las consultas en `AIUsage`.

## 8. Actualizar y volver atrás

```bash
git pull                                                   # versión revisada
LEXIEC_IMAGE_TAG=$(git rev-parse --short HEAD) docker compose -f infra/docker-compose.prod.yml up -d --build
```

- **Si la versión nueva falla:** volver a arrancar con la etiqueta de imagen anterior (`LEXIEC_IMAGE_TAG=<anterior> … up -d`, sin `--build`).
- **Si ya se aplicó una migración incompatible:** restaurar la copia previa (sección 6). Hacerlo solo tras confirmarlo, porque se pierden los datos posteriores.

**Detener sin borrar datos:**

```bash
docker compose -f infra/docker-compose.prod.yml down   # NUNCA «down -v» en producción: borra el volumen
```

## 9. `check --deploy`

Con la configuración de producción quedan **3 avisos aceptados a propósito**:

| Aviso | Motivo |
|---|---|
| `security.W008` (`SECURE_SSL_REDIRECT`) | La redirección de HTTP a HTTPS la hace Nginx; repetirla en Django es innecesario. |
| `security.W005` (`SECURE_HSTS_INCLUDE_SUBDOMAINS`) | No se impone HSTS a otros subdominios de `katarisoft.com` que LexiEC no controla. |
| `security.W021` (`SECURE_HSTS_PRELOAD`) | La precarga de HSTS es difícil de revertir; no procede en un proyecto académico. |

HSTS empieza en 3600 s (`DJANGO_HSTS_SECONDS`) y puede aumentarse cuando HTTPS esté estable.

## Qué se ha verificado y qué no

**Verificado en local** el 2026-10-19, con un proyecto Compose desechable, secretos aleatorios temporales y Docker 29.1.3 / Compose 2.40.3:

- **Construcción y salud:** la imagen se construye; db y backend quedan «healthy».
- **Migraciones:** `migrate` explícito.
- **Respuestas del servicio:**
  - `health` responde 200 `{"status":"ok"}`;
  - `areas` sin sesión responde 401;
  - un host no permitido recibe 400;
  - el CSS del Admin se sirve con 200 `text/css`.
- **Exposición y usuario:**
  - backend solo en `127.0.0.1:8001`;
  - db sin puertos publicados;
  - proceso con uid 10001.
- **Copia de seguridad:**
  - `pg_dump -Fc`;
  - restauración en una base nueva con los datos esperados: 1 usuario y 35 migraciones.
- **Persistencia** tras `down` y `up`.

**NO verificado:**

- el VPS, Nginx real, el certificado y el DNS;
- `createsuperuser` en el contenedor;
- volver atrás con la etiqueta de imagen;
- la carga de las fichas, que todavía no existe.
