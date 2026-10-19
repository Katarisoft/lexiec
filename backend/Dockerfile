# Imagen de producción del backend de LexiEC (E20).
# Sin secretos: toda la configuración llega por variables de entorno en tiempo
# de ejecución (ver infra/.env.production.example).
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# Estáticos del Admin. La clave es solo para este paso de construcción y no
# se usa en ejecución (no protege nada).
RUN DJANGO_ENV_FILE=/nonexistent DJANGO_DEBUG=0 \
    DJANGO_SECRET_KEY=solo-para-collectstatic-en-construccion \
    python manage.py collectstatic --noinput

RUN useradd --system --uid 10001 --home /app lexiec && chown -R lexiec:lexiec /app
USER lexiec

EXPOSE 8000

# Timeout de 60 s: mayor que el del proveedor de IA (30 s). Sin registrar
# cuerpos de petición; el access log solo incluye método, ruta y estado.
CMD ["gunicorn", "config.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "3", \
     "--timeout", "60", \
     "--access-logfile", "-"]
