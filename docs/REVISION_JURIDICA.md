# Revisión jurídica — LexiEC

Plantilla para Revisor Jurídico. **Ningún campo está completado:** el agente no registra aprobaciones. Solo Revisor Jurídico (o el propietario, transcribiendo su decisión) rellena las columnas de decisión.

Documento de apoyo: [docs/FUENTES.md](FUENTES.md) (inventario consultado el 2026-10-16).

## Instrucciones

1. Para cada documento (D01–D08), elegir la fuente de trabajo: A (edición del Registro Oficial), B (texto actualizado en dominio oficial) o C (ficha GOB.EC), o indicar otra fuente oficial con su URL.
2. Indicar hasta qué reforma se ha cotejado el texto. Si no se pudo cotejar, escribir «no cotejado».
3. Vigencia: dejar «no comprobada» salvo que se aporte evidencia (fecha y fuente de la comprobación).
4. Registrar limitaciones visibles para la persona usuaria, por ejemplo «texto no consolidado oficialmente; última reforma cotejada: …».
5. Decisión: **Aprobado**, **Rechazado** o **Requiere otra fuente**.
6. No incluir datos personales: la referencia de quien revisa es «Revisor Jurídico».

En E05, cada aprobación se registrará en el sistema con la cuenta de staff que el propietario asigne a Revisor Jurídico (`reviewed_by`) y la fecha de esta plantilla (`reviewed_at`).

## A. Documentos fuente

| ID | Documento | Fuente elegida (A/B/C/otra + URL) | Reforma cotejada | Vigencia (no comprobada / comprobada + evidencia) | Limitaciones para la persona usuaria | Decisión | Revisor | Fecha |
|---|---|---|---|---|---|---|---|---|
| D01 | Constitución de la República del Ecuador | | | no comprobada | | | Revisor Jurídico | |
| D02 | Código Civil (Codificación 2005-010) | | | no comprobada | | | Revisor Jurídico | |
| D03 | Código de la Niñez y Adolescencia | | | no comprobada | | | Revisor Jurídico | |
| D04 | Código del Trabajo (Codificación 2005-017) | | | no comprobada | | | Revisor Jurídico | |
| D05 | Ley Orgánica de Participación Ciudadana | | | no comprobada | | | Revisor Jurídico | |
| D06 | Ley Orgánica de Garantías Jurisdiccionales y Control Constitucional | | | no comprobada | | | Revisor Jurídico | |
| D07 | Ley Orgánica de Transparencia y Acceso a la Información Pública (2023) | | | no comprobada | | | Revisor Jurídico | |
| D08 | Ley Orgánica del Consejo de Participación Ciudadana y Control Social | | | no comprobada | | | Revisor Jurídico | |

## B. Bloqueos que requieren decisión

| ID | Pregunta | Respuesta de Revisor Jurídico | Fecha |
|---|---|---|---|
| B-01 | D03: ¿cuál es el texto vigente que debe usarse? ¿Se confirma la reforma del R.O. 279 (29-III-2023) y el estado del art. 106 tras la sentencia 28-15-IN/21? | | |
| B-02 | D05: ¿dónde obtener el texto con la reforma del R.O. 584-4S (21-VI-2024)? | | |
| P-02 | ¿Qué régimen permite reproducir fragmentos de textos normativos en la app y cómo debe atribuirse la fuente? | | |
| P-03 | ¿Hay reformas a D06 posteriores a 2020 o a D07 posteriores a 2023? | | |

## C. Temas por área

Detalle de cada tema en [docs/FUENTES.md](FUENTES.md): sección 7 (Familia), sección 8 (Laboral) y sección 9 (Constitucional y Participación Ciudadana).

Decisión: **Aprobado**, **Rechazado**, **Aprobado con cambios** (indicar cuáles) o **Requiere otra fuente**.

### C.1 Derecho de Familia

| ID | Tema | Localizadores propuestos | ¿Localizadores correctos y suficientes? | Fuente de texto autorizada para E05 | Decisión | Observaciones | Revisor | Fecha |
|---|---|---|---|---|---|---|---|---|
| F1 | Familia, matrimonio y capacidad para casarse | CRE art. 67; CC arts. 81, 83, 95 | | | | | Revisor Jurídico | |
| F2 | Unión de hecho | CRE art. 68; CC arts. 222, 223 | | | | | Revisor Jurídico | |
| F3 | Terminación del matrimonio y divorcio por mutuo consentimiento | CC arts. 105, 106, 107 | | | | | Revisor Jurídico | |
| F4 | Causas de divorcio | CC art. 110 | | | | | Revisor Jurídico | |
| F5 | Pensión de alimentos | CONA Libro II Tít. V, arts. innum. 1-5; CRE art. 69 | | | | | Revisor Jurídico | |
| F6 | Patria potestad y tenencia | CONA arts. 105, 106, 118, 119 | | | | | Revisor Jurídico | |
| F7 | Régimen de visitas | CONA arts. 122, 123, 124 | | | | | Revisor Jurídico | |
| F-alt1 | Alimentos entre otros parientes (alternativa) | CC art. 349 | | | | | Revisor Jurídico | |
| F-alt2 | Derechos de niñas, niños y adolescentes (alternativa) | CRE arts. 44, 45 | | | | | Revisor Jurídico | |

### C.2 Derecho Laboral

| ID | Tema | Localizadores propuestos | ¿Localizadores correctos y suficientes? | Fuente de texto autorizada para E05 | Decisión | Observaciones | Revisor | Fecha |
|---|---|---|---|---|---|---|---|---|
| L1 | Contrato de trabajo y sus tipos | CT arts. 8, 11, 14; CRE art. 33 | | | | | Revisor Jurídico | |
| L2 | Jornada máxima y horas extra | CT arts. 47, 55 | | | | | Revisor Jurídico | |
| L3 | Décima tercera y décima cuarta remuneración | CT arts. 111, 113 | | | | | Revisor Jurídico | |
| L4 | Vacaciones anuales | CT art. 69 | | | | | Revisor Jurídico | |
| L5 | Despido intempestivo | CT arts. 169, 188 | | | | | Revisor Jurídico | |
| L6 | Desahucio y bonificación | CT arts. 184, 185 | | | | | Revisor Jurídico | |
| L7 | Participación en utilidades | CT art. 97 | | | | | Revisor Jurídico | |
| L-alt1 | Licencia por maternidad y paternidad (alternativa) | CT art. 152; CRE art. 332 | | | | | Revisor Jurídico | |
| L-alt2 | Afiliación al IESS (alternativa) | CT art. 42 num. 31; CRE art. 34 | | | | | Revisor Jurídico | |

### C.3 Derecho Constitucional y Participación Ciudadana

| ID | Tema | Localizadores propuestos | ¿Localizadores correctos y suficientes? | Fuente de texto autorizada para E05 | Decisión | Observaciones | Revisor | Fecha |
|---|---|---|---|---|---|---|---|---|
| C1 | Acción de protección | CRE art. 88; LOGJCC arts. 39-42 | | | | | Revisor Jurídico | |
| C2 | Hábeas corpus | CRE art. 89; LOGJCC art. 43 | | | | | Revisor Jurídico | |
| C3 | Hábeas data | CRE art. 92; LOGJCC arts. 49-51 | | | | | Revisor Jurídico | |
| C4 | Acceso a la información pública | CRE arts. 18, 91; LOTAIP arts. 7, 32, 34, 36; LOGJCC arts. 47-48 | | | | | Revisor Jurídico | |
| C5 | Iniciativa popular normativa y consulta popular | CRE arts. 103, 104; LOPC arts. 6, 19 | | | | | Revisor Jurídico | |
| C6 | Silla vacía | CRE art. 101; LOPC art. 77 | | | | | Revisor Jurídico | |
| C7 | Rendición de cuentas y veedurías | CRE art. 208; LOPC arts. 84, 88-90; LOCPCCS arts. 9, 10, 63 | | | | | Revisor Jurídico | |
| C-alt1 | Derecho de petición (alternativa) | CRE art. 66 num. 23 | | | | | Revisor Jurídico | |
| C-alt2 | Derechos de participación (alternativa) | CRE arts. 61, 95, 100 | | | | | Revisor Jurídico | |

Pregunta adicional para Revisor Jurídico: ¿se confirma que, tras la sentencia 018-18-SIN-CC, el art. 104 y los demás artículos afectados por la Enmienda de 2015 rigen con su texto original?

## D. Muestra de respuestas del asistente

Se completará en E18 con la matriz de evaluación. No se registran aquí respuestas simuladas.
