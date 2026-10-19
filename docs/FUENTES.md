# Inventario de fuentes oficiales — LexiEC

Entrega E04a. Fecha de consulta de todas las fuentes: **2026-10-16**.  
Estado general: **PENDIENTE DE REVISIÓN** por Revisor Jurídico. Nada de este inventario está aprobado ni puede alimentar al asistente todavía.

Este documento registra qué se consultó, dónde y qué decía cada portada. No transcribe artículos ni afirma vigencia. Los temas por área (7 por área) se añadirán en E04b (Familia), E04c (Laboral) y E04d (Constitucional y Participación Ciudadana).

## 1. Criterios

### 1.1 Tipos de evidencia

| Tipo | Qué es | Uso permitido |
|---|---|---|
| **A — Edición oficial** | Facsímil de una edición del Registro Oficial (publicación original o reforma). | Prueba la publicación y el texto en esa fecha. No incluye reformas posteriores. |
| **B — Texto actualizado en dominio oficial** | Compilación con reformas incorporadas, alojada por una entidad pública (`*.gob.ec`). El compilador puede ser una editorial privada o no estar identificado. | Referencia de trabajo para localizar artículos. **No es una consolidación oficial**: cada fragmento debe cotejarlo Revisor Jurídico. |
| **C — Ficha referencial** | Ficha del portal GOB.EC con metadatos y un PDF adjunto. | Puntero complementario. El propio portal advierte: «Esta información es referencial, puede encontrarse desactualizada». |

### 1.2 Fuentes excluidas como respaldo

No se usan como respaldo legal, aunque aparezcan en buscadores:
- copias subidas por usuarios (Scribd);
- portales comerciales o de divulgación (derechoecuador.com, ecuadorlegalonline.com, noticias de editoriales);
- repositorios universitarios (por ejemplo, ESPOL);
- espejos internacionales (WIPO Lex, FAOLEX, ACNUR);
- texto generado por modelos de IA.

Pueden servir como pista para buscar la fuente oficial, nunca como evidencia.

### 1.3 Advertencias generales

- Una URL oficial no prueba que el texto esté actualizado. Las «últimas reformas» indicadas en las portadas de tipo B son declaraciones del compilador y deben verificarse contra el Registro Oficial.
- Las copias de tipo B de distintas entidades no coinciden entre sí en la última reforma (ver D01, D04 y D06).
- Los archivos descargados se conservaron solo fuera del repositorio. Se registra su SHA-256 para poder comprobar más adelante si la URL sigue sirviendo el mismo archivo.

## 2. Inventario de documentos

Cada documento tiene un identificador estable (D01…D08) para E04b–E05. Las áreas indican dónde se prevé usarlo.

### D01 — Constitución de la República del Ecuador

Áreas previstas: Constitucional y Participación; Familia y Laboral (derechos generales).

| Tipo | URL | Lo que consta en el documento | Págs. | SHA-256 |
|---|---|---|---:|---|
| A | https://esacc.corteconstitucional.gob.ec/storage/api/v1/10_DWL_FL/eyJjYXJwZXRhIjoicm8iLCJ1dWlkIjoiMDZmMTE3NmQtMGMxNC00OTNmLWFhZGYtMjQ0ZmQ0OWQ1OTVmLnBkZiJ9 | «REGISTRO OFICIAL — Año II — Quito, Lunes 20 de Octubre del 2008 — Nº449». Edición original. | 82 | `93a23b0ce6478432484a9e0f5d56effdd1153bf0f807fbaf6d0cb3e6d6822ebe` |
| B | https://portal.compraspublicas.gob.ec/sercop/wp-content/uploads/2025/11/CONSTITUCION-DE-LA-REPUBLICA-DEL-ECUADOR.pdf | «Registro Oficial No. 449, 20 de Octubre 2008 — Normativa: Vigente — Última Reforma: Tercer Suplemento del Registro Oficial 568, 30-V-2024». Publicado por SERCOP en su sección de normativa. **Compilación de Ediciones Legales**: cada página indica «Todos los derechos reservados. Prohibida su reproducción parcial o total». | 164 | `d930a39feca3168b56991c0ee9ba2b487fd132e03488ed86fc342f7c9fe2d60e` |
| C | https://www.gob.ec/regulaciones/constitucion-republica-ecuador | Tipo «Carta Suprema»; emisora «Asamblea Constituyente»; «R. O. 449 Año 2008», 2008-10-20. Última reforma no indicada. PDF adjunto: `constitucion_de_bolsillo.pdf` (subido en 2018-11; edición no identificada). | 218 | `9514ad12240826c650d8ba75f3164f0ca22af389aa291e2fa227fb02294d85c2` |

Limitaciones: la edición A no contiene reformas posteriores a 2008. La B declara una reforma de 2024 que no se ha cotejado con su edición del Registro Oficial. No se identificó la fecha de la edición «de bolsillo» de GOB.EC.

### D02 — Código Civil (Codificación No. 2005-010)

Área prevista: Familia.

| Tipo | URL | Lo que consta en el documento | Págs. | SHA-256 |
|---|---|---|---:|---|
| C + PDF | https://www.gob.ec/regulaciones/codigo-civil-codificacion-no-2005-010 — PDF: https://www.gob.ec/sites/default/files/regulations/2025-09/Documento_C%C3%B3digo-Civil-2025.pdf | Ficha: tipo «Ley orgánica»; emisora «Congreso Nacional»; «R.O. 46»; fecha de publicación **2005-01-24**; última reforma «Segundo Suplemento del Registro Oficial 61, 17-VI-2025». PDF: «Suplemento del Registro Oficial No. 46, **24 de Junio 2005** — Normativa: Vigente — Última Reforma: Segundo Suplemento del Registro Oficial 61, 17-VI-2025». **Compilación de Ediciones Legales** con el aviso «Prohibida su reproducción parcial o total» en cada página. | 392 | `7c4c66f757ed05ded44bf321a58c2977a385e62e68a1a9b9d33303d1481c8fd8` |

Limitaciones: la fecha de publicación de la ficha (enero) no coincide con la del PDF (junio). No se localizó la edición A original (R.O. Suplemento 46) ni la de la reforma de 2025.

### D03 — Código de la Niñez y Adolescencia

Área prevista: Familia.

| Tipo | URL | Lo que consta en el documento | Págs. | SHA-256 |
|---|---|---|---:|---|
| C + PDF | https://www.gob.ec/regulaciones/codigo-ninez-adolescencia — PDF: https://www.gob.ec/sites/default/files/regulations/2018-09/Documento_C%C3%B3digo-Ni%C3%B1ez-Adolescencia.pdf | Ficha: tipo «Código Orgánico»; emisora «Asamblea Nacional»; «R.O. 737, año 2017», 2017-05-31. PDF: «Ley 100 — Registro Oficial 737 de 03-ene.-2003 — Ultima modificación: 31-may.-2017 — Estado: Reformado». Compilación de **Lexis** (pie «LEXIS FINDER - www.lexis.com.ec»). | 115 | `8f4e8694bcbe9b6bc9957e3bbe40f951fb321b6340120ff07119fb70959542c0` |

**BLOQUEO:** no se encontró en un dominio oficial un texto con reformas posteriores a 2017.
- Copias de terceros (excluidas) mencionan una reforma en el Suplemento del R.O. 279, 29-III-2023: **no verificado**.
- Según la Asamblea Nacional (noticia de 2026-08-26), una comisión aprobó el texto final de un proyecto de reforma a los Libros I, II y III. Es un proyecto, no una ley publicada.
- Pista **no verificada**, relevante para tenencia: una sentencia de la Corte Constitucional (28-15-IN/21) habría declarado inconstitucionales partes del art. 106. Revisor Jurídico debe confirmarlo antes de proponer ese tema.

### D04 — Código del Trabajo (Codificación No. 2005-017)

Área prevista: Laboral.

| Tipo | URL | Lo que consta en el documento | Págs. | SHA-256 |
|---|---|---|---:|---|
| B | https://portal.compraspublicas.gob.ec/sercop/wp-content/uploads/2026/08/CODIGO-DEL-TRABAJO.pdf | «TIPO NORMA: Codificación — NÚMERO DE NORMA: 17 — FECHA DE PUBLICACIÓN: 2005-12-16 — Registro Oficial Suplemento — NÚMERO DE PUBLICACIÓN: 167 — ESTADO: Reformado — ÚLTIMA REFORMA: 2026-04-09». Compilador no identificado. | 159 | `94d87989023bb40b456319aba9f6c7f72426232c9e5f62c07ae120dc3739a84d` |
| B | https://www.trabajo.gob.ec/wp-content/uploads/2024/01/CODIGO_DEL_TRABAJO-CT.pdf | Ministerio del Trabajo. «Suplemento del Registro Oficial No. 167, 16 de Diciembre 2005 — Normativa: Vigente — Última Reforma: Suplemento del Registro Oficial 309, 12-V-2023». **Compilación de Ediciones Legales** con el aviso «Prohibida su reproducción parcial o total». | 199 | `0f41bb82933e6795ac4d42438a76f2d0947e6c9dab77c85551b899ab058160c2` |
| B | https://esacc.corteconstitucional.gob.ec/storage/api/v1/10_DWL_FL/e2NhcnBldGE6ICJub3RhaXAyMDIzIiwgdXVpZDoiZWU0MDUzZmYtYzFjOS00YjU4LThkMTItYTRlZTRlM2RkZjMyLnBkZiJ9 | Repositorio de la Corte Constitucional. «Bajado 30 abr 2022 — Normativa: Vigente — Última Reforma: Segundo Suplemento del Registro Oficial 44, 18-IV-2022». | 184 | `b20b8420677afe406791419e585becd0f9d5105207d80d3a8c23a9aa4d50ca38` |
| C | https://www.gob.ec/regulaciones/codigo-trabajo | Ficha: tipo «Ley ordinaria»; emisora «Asamblea Nacional»; «R.O. 167 Año 2005», 2005-12-16. Última reforma no indicada. PDF adjunto subido en 2018-10 (no descargado). | — | — |

Limitaciones: las tres copias B declaran últimas reformas distintas (2022, 2023 y 2026). La más reciente (SERCOP) da la fecha 2026-04-09 sin identificar la edición del Registro Oficial. Es imprescindible cotejar cada artículo usado.

### D05 — Ley Orgánica de Participación Ciudadana

Área prevista: Constitucional y Participación.

| Tipo | URL | Lo que consta en el documento | Págs. | SHA-256 |
|---|---|---|---:|---|
| C + PDF | https://www.gob.ec/regulaciones/ley-organica-participacion-ciudadana — PDF: https://www.gob.ec/sites/default/files/regulations/2018-09/Documento_Ley-Org%C3%A1nica-Participaci%C3%B3n-Ciudadana.pdf | Ficha: tipo «Ley orgánica»; emisora «Presidencia de la República del Ecuador» (así consta); «R.O 175, Año 2010», 2010-04-20. PDF: «Registro Oficial Suplemento 175 de 20-abr.-2010 — Ultima modificación: 11-may.-2011 — Estado: Vigente». Compilación de **Lexis**. | 31 | `74c6615070c3182771beb47f7e988ee0ba95ac2df17d43168c0c1b56a948c843` |

**BLOQUEO:** el único texto oficial disponible es de 2011.
- Varias referencias, ninguna verificada en el Registro Oficial, indican una ley reformatoria publicada en el Cuarto Suplemento del R.O. 584, 21-VI-2024. No se localizó esa edición.
- La copia actualizada que alojaba ame.gob.ec (`/wp-content/uploads/2024/07/LEY-ORGANICA-DE-PARTICIPACION-CIUDADANA.pdf`) devolvía **HTTP 404** el 2026-10-16.
- Una ordenanza municipal (Edición Especial R.O. 206, 2025) cita la ley como «Suplemento del Registro Oficial Nro. 75»: incoherencia con el n.º 175 de las demás fuentes.

### D06 — Ley Orgánica de Garantías Jurisdiccionales y Control Constitucional (LOGJCC)

Área prevista: Constitucional y Participación (acción de protección, hábeas data, etc.).

| Tipo | URL | Lo que consta en el documento | Págs. | SHA-256 |
|---|---|---|---:|---|
| C + PDF | https://www.gob.ec/regulaciones/ley-organica-garantias-jurisdiccionales-control-constitucional — PDF: https://www.gob.ec/sites/default/files/regulations/2020-03/Documento_LEY-ORG%C3%81NICA-GARANT%C3%8DAS-JURISDICCIONALES.pdf | Ficha: tipo «Ley orgánica»; emisora «Asamblea Nacional»; «R.O. 2do Suplemento No. 52», 2009-10-22 (fecha de suscripción mostrada: 2019-09-10). PDF: «Segundo Suplemento del Registro Oficial No.52, 22 de Octubre 2009 — Normativa: Vigente — Última Reforma: Suplemento del Registro Oficial 134, 3-II-2020». | 62 | `6d878b988dec8ed60e40e5b541fbd606e98843402cc431b33d925d361317803e` |
| B | https://www.casadelacultura.gob.ec/lotaip/25/2018/Enero/ley_organica_de_garantias_jurisdicionales.pdf | «Última Reforma: Suplemento del Registro Oficial 75, 8-IX-2017». Versión anterior a la de GOB.EC. | 40 | `0b52008197017e71683e96d7b51b35f67cfd63226c507bec8accffba23b0d990` |

Limitaciones: no se comprobó si hubo reformas posteriores a 2020. La fecha de suscripción de la ficha (2019) no es coherente con la publicación de 2009.

### D07 — Ley Orgánica de Transparencia y Acceso a la Información Pública (2023)

Área prevista: Constitucional y Participación.

| Tipo | URL | Lo que consta en el documento | Págs. | SHA-256 |
|---|---|---|---:|---|
| A (vía GOB.EC) | https://www.gob.ec/regulaciones/ley-organica-transparencia-acceso-informacion-publica-2023 — PDF: https://www.gob.ec/sites/default/files/regulations/2024-06/Documento%20Ley_Org_Transparencia_Acceso_Informaci%C3%B3n.pdf | El PDF es el facsímil del «Segundo Suplemento Nº 245 — Registro Oficial — Año I — Quito, martes 7 de febrero de 2023». Ficha: tipo «Ley orgánica»; emisora «Asamblea Nacional»; 2023-02-07 (suscripción 2023-02-03). | 33 | `b27c0ea582a7cdb37ef6ddcfceb79db02ded0712b2f03d16e80ef93b6ffbc437` |

Limitaciones: es la publicación original y no incluye posibles reformas. No debe confundirse con la ley anterior de 2004, cuya situación debe confirmar Revisor Jurídico. Hay un reglamento general (Decreto Ejecutivo 124, R.O. 484, 24-I-2024) **no verificado** en fuente oficial.

### D08 — Ley Orgánica del Consejo de Participación Ciudadana y Control Social

Área prevista: Constitucional y Participación.

| Tipo | URL | Lo que consta en el documento | Págs. | SHA-256 |
|---|---|---|---:|---|
| B | https://portal.compraspublicas.gob.ec/sercop/wp-content/uploads/2026/08/LEY-ORGANICA-DEL-CONSEJO-DE-PARTICIPACION-CIUDADANA-Y-CONTROL-SOCIAL.pdf | «TIPO NORMA: Ley — FECHA DE PUBLICACIÓN: 2009-09-09 — Registro Oficial Suplemento — NÚMERO DE PUBLICACIÓN: 22 — ESTADO: Reformado — ÚLTIMA REFORMA: 2024-11-11». Compilador no identificado. | 26 | `568f3ffecd8ee87d9d18f1bb9ced87b8a8ee189b2a47ad28f37336b5f8157ea3` |

Limitaciones: la reforma de 2024 no se ha cotejado con su edición del Registro Oficial.

### Documentos no inventariados todavía

Se añadirán en E04b–E04d solo si los temas aprobados los necesitan:
- Código Orgánico General de Procesos (procedimientos de familia);
- Ley de Seguridad Social (afiliación);
- reglamentos de las leyes anteriores.

## 3. Prueba acotada de la API de GOB.EC

Documentación: https://www.gob.ec/api. API pública de solo lectura en JSON, sin autenticación indicada. Endpoint consultado: `GET https://www.gob.ec/api/v1/regulaciones?page=N`.

| Observación (2026-10-16) | Resultado |
|---|---|
| Conexión por HTTP/2 | Falla siempre (`curl: (92) … PROTOCOL_ERROR`) en los 4 endpoints probados. |
| Conexión por HTTP/1.1 | `regulaciones` y `tramites-regulaciones` responden 200 `application/json`. |
| Tamaño de página | 250 regulaciones por página. |
| Página 0 por tipo | Resolución 109, Acuerdo ministerial 93, Ordenanza municipal 23, Decreto ejecutivo 17, Reglamento de ley 4, Ley ordinaria 1, Ley orgánica 1, Norma internacional 1, Código Orgánico 1. |
| Cobertura de D01–D08 en la página 0 | Ninguno aparece. Predomina la normativa vinculada a trámites. |
| Estabilidad | La página 1 agotó el tiempo de espera (60 s); un único reintento respondió 200 en 16,6 s. Se detuvo la paginación para no insistir. |
| Licencia | La página de la API declara CC BY 4.0, pero su insignia enlaza a CC BY 3.0 Ecuador: incoherencia. |
| Calidad de metadatos | Fichas con incoherencias (fechas de D02, D03 y D06; emisora de D05) y advertencia de información referencial. |

Conclusión: la API sirve como pista complementaria para localizar fichas y PDF, pero **la app no dependerá de ella**. No se consumirá en tiempo de ejecución ni en la importación de E05 sin una nueva autorización.

## 4. Condiciones de uso y redistribución

- **Registro Oficial** (https://www.registroficial.gob.ec/): la portada revisada no muestra condiciones de uso ni de redistribución.
- **GOB.EC:** licencia Creative Commons Atribución (versión incoherente, ver arriba).
- **SERCOP, Ministerio del Trabajo, Corte Constitucional y Casa de la Cultura:** en las páginas revisadas no consta ninguna licencia para los PDF.
- **Compilaciones privadas (actualizado en E04b):** varias copias alojadas en dominios oficiales son compilaciones editoriales.
  - **Ediciones Legales**, con «Todos los derechos reservados. Prohibida su reproducción parcial o total» en cada página: D01-B (SERCOP), D02 (GOB.EC) y D04-B (Ministerio del Trabajo).
  - **Lexis**, con el pie «LEXIS FINDER»: D03 y D05 (GOB.EC).
  - Mientras Revisor Jurídico no confirme el régimen aplicable (P-02), **no se copiará texto de esas compilaciones a la base de datos**. En E05 los fragmentos deben tomarse de ediciones del Registro Oficial (tipo A) o de copias sin aviso restrictivo, y servir esas compilaciones solo para localizar artículos.
  - Las copias de SERCOP 2026 (D04, D08), de la Corte Constitucional (D04, 2022) y de GOB.EC para D06 no muestran marca de compilador ni aviso restrictivo en su texto.

**PENDIENTE (Revisor Jurídico):** confirmar el régimen aplicable a la reproducción de textos normativos en Ecuador y la atribución adecuada antes de E05. Este inventario no afirma que los textos sean libremente redistribuibles.

## 5. Bloqueos y pendientes

| ID | Pendiente | Responsable |
|---|---|---|
| B-01 | D03: texto oficial con reformas posteriores a 2017; confirmar la reforma de 2023 y el estado del art. 106. | Revisor Jurídico / búsqueda en el Registro Oficial |
| B-02 | D05: edición del R.O. 584-4S (21-VI-2024) o texto oficial actualizado. | Revisor Jurídico / búsqueda en el Registro Oficial |
| P-01 | Elegir la fuente de trabajo de cada documento (A, B o C) y cotejar las últimas reformas declaradas. | Revisor Jurídico |
| P-02 | Confirmar las condiciones de reproducción y atribución. | Revisor Jurídico |
| P-03 | Comprobar si hubo reformas a D06 posteriores a 2020 y a D07 posteriores a 2023. | Revisor Jurídico |

## 6. Correspondencia con el esquema (E03)

| Campo de `SourceDocument` | Origen en este inventario |
|---|---|
| `institution` | Emisora según la edición oficial, no la entidad que aloja la copia. |
| `title` | Título del documento. |
| `official_url` | Fuente elegida por Revisor Jurídico (P-01). |
| `publication_reference`, `publication_date` | Edición original del Registro Oficial. |
| `version_label` | Última reforma cotejada, no la declarada por un compilador sin cotejar. |
| `retrieved_at` | 2026-10-16, o la fecha de una nueva consulta. |
| `text_hash` | Hash del texto incorporado en E05 (distinto del hash del PDF registrado aquí). |
| `validity_status` | «No comprobada» salvo evidencia aportada por Revisor Jurídico. |
| `limitations` | Limitaciones de esta sección. |

## 7. Temas propuestos — Derecho de Familia (E04b)

Fecha de elaboración: 2026-10-16. **Todos los temas están PENDIENTES DE APROBACIÓN** por Revisor Jurídico. Los localizadores se identificaron en las copias de trabajo indicadas; el texto no se ha cotejado con el Registro Oficial y no se transcribe aquí.

Abreviaturas de copias de trabajo y páginas del PDF:
- **CRE-A:** D01 tipo A, R.O. 449 original.
- **CRE-B:** D01 tipo B, SERCOP / Ediciones Legales.
- **CC:** D02, PDF de GOB.EC / Ediciones Legales (2025).
- **CONA:** D03, PDF de GOB.EC / Lexis, «Ultima modificación: 31-may.-2017».

### Resumen

| ID | Pregunta ciudadana | Documento y localizador | Disponibilidad de texto reproducible | Estado |
|---|---|---|---|---|
| F1 | ¿Qué reconoce la ley como familia y matrimonio, y quiénes pueden casarse? | D01 art. 67; D02 arts. 81, 83 y 95 | Art. 67: tipo A disponible. Arts. del CC: solo compilación con reproducción prohibida | Pendiente de aprobación |
| F2 | ¿Cuándo existe una unión de hecho y qué derechos genera? | D01 art. 68; D02 arts. 222 y 223 | Art. 68: tipo A. CC: igual que F1 | Pendiente de aprobación |
| F3 | ¿Cómo termina un matrimonio y qué es el divorcio por mutuo consentimiento? | D02 arts. 105, 106 y 107 | Igual que F1; el procedimiento remite al COGEP (no inventariado) | Pendiente de aprobación |
| F4 | ¿Cuáles son las causas de divorcio? | D02 art. 110 | Igual que F1 | Pendiente de aprobación |
| F5 | ¿Quién tiene derecho a pensión de alimentos y quién debe pagarla? | D03 Libro II, Título V, arts. innumerados 1 a 5; D01 art. 69 | **Bloqueo B-01**: solo texto de 2017 (Lexis). Art. 69: tipo A | Pendiente de aprobación |
| F6 | ¿Qué son la patria potestad y la tenencia, y cómo se decide? | D03 arts. 105, 106, 118 y 119 | **Bloqueo B-01** y pista no verificada sobre la sentencia 28-15-IN/21 (art. 106) | Pendiente de aprobación |
| F7 | ¿Cómo se regula el régimen de visitas? | D03 arts. 122, 123 y 124 | **Bloqueo B-01** | Pendiente de aprobación |

Alternativas si se rechaza algún tema:
- **F-alt1:** alimentos entre otros parientes (D02 art. 349; CC pág. 54).
- **F-alt2:** derechos de niñas, niños y adolescentes (D01 arts. 44 y 45; CRE-A pág. 15).

### Detalle por tema

**F1 — Familia, matrimonio y capacidad para casarse**
- Localizadores:
  - D01 art. 67 (CRE-A pág. 20; CRE-B pág. 27);
  - D02 art. 81 (CC pág. 16), art. 83 (pág. 17) y art. 95 (pág. 18).
- Notas del compilador:
  - art. 81 «Sustituido por la Sentencia 10-18-CN/19, R.O. E.C. 96, 8-VII-2019»;
  - arts. 83 y 95 «Sustituido por … Ley s/n, R.O. 526-2S, 19-VI-2015».
- Ediciones A que habría que localizar: R.O. Edición Constitucional 96 (2019) y R.O. 526-2S (2015).
- Riesgo: confundir el texto original de 2005 con el reformado.

**F2 — Unión de hecho**
- Localizadores: D01 art. 68 (CRE-A pág. 21; CRE-B pág. 27); D02 arts. 222 y 223 (CC pág. 38, Título VI «De las uniones de hecho»).
- Nota del compilador: ambos artículos del CC «Sustituido por … Ley s/n, R.O. 526-2S, 19-VI-2015».
- Limitación: la formalización ante la autoridad competente y el registro dependen de normas no inventariadas.

**F3 — Terminación del matrimonio y divorcio por mutuo consentimiento**
- Localizadores: D02 arts. 105, 106 y 107 (CC pág. 20).
- Nota del compilador: art. 107 «Sustituido por el num. 2 de la Disposición Reformatoria Quinta del Código s/n, R.O. 506-S, 22-V-2015»; remite el procedimiento al Código Orgánico General de Procesos.
- Limitación: el procedimiento (judicial o, en su caso, notarial) no está en D01–D08. Si se aprueba, la ficha solo explicará la regla sustantiva o habrá que inventariar el COGEP.

**F4 — Causas de divorcio**
- Localizador: D02 art. 110 (CC pág. 21).
- Nota del compilador: «Sustituido por el Art. 11 de la Ley s/n, R.O. 526-2S, 19-VI-2015».
- Riesgo: temas de violencia intrafamiliar; la ficha debe remitir a ayuda profesional y no orientar casos concretos.

**F5 — Pensión de alimentos**
- Localizadores: D03 Libro II, Título V «Del derecho a alimentos» (CONA pág. 32), arts. innumerados 1 a 5 (en la compilación aparecen numerados 1 a 5; «Titulares» y «Obligados» en pág. 33); D01 art. 69 (CRE-A pág. 21).
- Nota del compilador: título sustituido por Ley publicada en el R.O. Suplemento 643, 28-VII-2009.
- **Riesgo alto:** el texto disponible es de 2017. En la propia compilación aparecen artículos duplicados (24 y 25) y el art. 22 «Apremio personal» sin texto. No se proponen temas sobre apremio ni sobre montos de la tabla de pensiones.

**F6 — Patria potestad y tenencia**
- Localizadores: D03 arts. 105 y 106 (CONA pág. 27), arts. 118 y 119 (pág. 31).
- **Riesgo alto:** bloqueo B-01. Además, hay una pista no verificada sobre la sentencia 28-15-IN/21 que habría declarado inconstitucionales partes del art. 106, y un proyecto de reforma aprobado en comisión (2026-08-26) que no es ley. No publicar sin confirmación de Revisor Jurídico.

**F7 — Régimen de visitas**
- Localizadores: D03 arts. 122, 123 y 124 (CONA págs. 31-32).
- Riesgo: bloqueo B-01.

### Conclusión para Familia

- Solo hay texto de tipo A (reproducible, sujeto a P-02) para los artículos constitucionales (67, 68 y 69).
- Los artículos del Código Civil requieren localizar las ediciones del R.O. de 2015 y 2019 citadas, o que Revisor Jurídico autorice otra fuente.
- F5–F7 dependen de resolver B-01.

Ninguna ficha de Familia puede alcanzar el estado «publicable» en E05 sin esas decisiones.
