# Changelog

Cambios relevantes de LexiEC. El formato sigue la idea de [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [Sin publicar]

### Añadido

- Proyecto Flutter base `lexiec` en `mobile/` (solo Android, identificador `com.katarisoft.lexiec`).
- Proyecto Django 5.2 LTS base en `backend/`, configurado por variables de entorno y con PostgreSQL.
- `backend/requirements.txt` con versiones fijadas y `backend/.env.example` sin valores secretos.
- Registro de versiones, decisiones y comandos de arranque en `docs/ESTADO.md`.

### Seguridad

- `.gitignore` ampliado para excluir `.env.*` (excepto `.env.example`), claves de firma, entornos virtuales y bases SQLite.
- Eliminada la `SECRET_KEY` insegura que genera la plantilla de Django.
