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

### Cambiado

- El backend carga `backend/.env` con `python-dotenv` 1.2.4, sin sobrescribir variables del entorno.
- Sustituido el contador de la plantilla de Flutter por la pantalla provisional de LexiEC.

### Eliminado

- `workflows/ci.yml`, que no estaba activo, sustituido por los workflows de `.github/workflows/`.

### Seguridad

- `.gitignore` ampliado para excluir `.env.*` (excepto `.env.example`), claves de firma, entornos virtuales y bases SQLite.
- Eliminada la `SECRET_KEY` insegura que genera la plantilla de Django.
