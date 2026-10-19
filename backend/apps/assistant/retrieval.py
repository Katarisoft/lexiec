"""Recuperación de fragmentos para el asistente, sin proveedor de IA.

Reglas:
- Filtro obligatorio de área y solo fragmentos elegibles (revisados y
  publicados, enlazados a fichas publicadas del área).
- Búsqueda de texto completo de PostgreSQL en español, sin tildes, sobre el
  texto y el localizador, más los términos controlados de las fichas.
- Contexto acotado (número de fragmentos y caracteres).
- Si no hay respaldo, se devuelve `sufficient=False` para abstenerse sin
  llamar al proveedor.
- Nunca usa comentarios ni historial como evidencia.

El criterio de suficiencia es PROVISIONAL: debe validarse con la matriz de
preguntas de E18 sobre la colección revisada (ver docs/RECUPERACION.md).
"""

import re
import unicodedata
from dataclasses import dataclass, field

from django.contrib.postgres.search import SearchQuery, SearchRank, SearchVector
from django.conf import settings
from django.db.models import Case, F, Func, Q, TextField, Value, When

from apps.library.choices import PublicationStatus, ReviewStatus
from apps.library.models import LegalArea, SourceFragment, TopicCard

MAX_FRAGMENTS = 5
DEFAULT_MIN_COVERAGE = 0.5
MAX_CONTEXT_CHARS = 6000
SEARCH_CONFIG = 'spanish'

# Palabras vacías mínimas: preguntas ciudadanas frecuentes que no aportan.
STOPWORDS = {
    'a', 'al', 'algo', 'como', 'con', 'cual', 'cuales', 'cuando', 'cuanto',
    'de', 'del', 'donde', 'el', 'ella', 'en', 'es', 'esta', 'este', 'hay',
    'la', 'las', 'le', 'lo', 'los', 'me', 'mi', 'mis', 'muy', 'no', 'o',
    'para', 'pero', 'por', 'puede', 'puedo', 'que', 'quien', 'se', 'si',
    'sin', 'sobre', 'su', 'sus', 'tengo', 'tiene', 'un', 'una', 'unos', 'y',
    'ya', 'yo', 'debo', 'deben', 'hacer', 'cuantos', 'cuantas', 'mas',
}
_ACCENTED = 'áéíóúüñÁÉÍÓÚÜÑ'
_PLAIN = 'aeiouunAEIOUUN'


def normalize(text: str) -> str:
    """Minúsculas y sin tildes (la ñ pasa a n, igual que en la base)."""
    decomposed = unicodedata.normalize('NFD', text.lower())
    return ''.join(c for c in decomposed if unicodedata.category(c) != 'Mn')


def keywords(question: str) -> list[str]:
    words = re.findall(r'[a-z0-9]+', normalize(question))
    return list(dict.fromkeys(w for w in words if len(w) > 2 and w not in STOPWORDS))


def _plain(expression):
    """translate(lower(expr), 'áé…', 'ae…') en PostgreSQL, sin extensiones."""
    lowered = Func(expression, function='LOWER', output_field=TextField())
    return Func(
        lowered, Value(_ACCENTED), Value(_PLAIN), function='TRANSLATE', output_field=TextField()
    )


@dataclass(frozen=True)
class RetrievedFragment:
    id: int
    document_title: str
    document_url: str
    locator: str
    text: str
    score: float
    coverage: float = 0.0


@dataclass(frozen=True)
class RetrievalResult:
    sufficient: bool
    reason: str
    fragments: list = field(default_factory=list)
    keywords: list = field(default_factory=list)
    best_coverage: float = 0.0


def min_coverage() -> float:
    """Fracción mínima de palabras clave cubiertas por el mejor fragmento.

    Valor PROVISIONAL (0.5) hasta validarlo con la matriz de E18; se puede
    ajustar con ASSISTANT_MIN_COVERAGE sin cambiar código.
    """
    return float(getattr(settings, 'ASSISTANT_MIN_COVERAGE', DEFAULT_MIN_COVERAGE))


def candidate_fragments(area: LegalArea):
    """Fragmentos elegibles enlazados a fichas publicadas del área."""
    return (
        SourceFragment.objects.eligible_for_assistant()
        .filter(
            topics__area=area,
            topics__publication_status=PublicationStatus.PUBLISHED,
            topics__review_status=ReviewStatus.APPROVED,
        )
        .distinct()
    )


def _topics_matching_terms(area: LegalArea, terms: list[str]):
    """Fichas publicadas del área cuyos términos controlados contienen alguna
    palabra clave (sin tildes ni mayúsculas)."""
    terms_text = _plain(
        Func(F('search_terms'), Value(' '), function='array_to_string', output_field=TextField())
    )
    match = Q()
    for term in terms:
        match |= Q(terms_text__contains=term)
    return (
        TopicCard.objects.published()
        .filter(area=area)
        .annotate(terms_text=terms_text)
        .filter(match)
        .values('pk')
    )


def retrieve(
    question: str,
    area: LegalArea,
    *,
    max_fragments: int = MAX_FRAGMENTS,
    max_chars: int = MAX_CONTEXT_CHARS,
) -> RetrievalResult:
    if area is None:
        raise ValueError('El área es obligatoria para recuperar fragmentos.')

    terms = keywords(question)
    if not terms:
        return RetrievalResult(sufficient=False, reason='empty_query')

    vector = SearchVector(_plain(F('text')), weight='B', config=SEARCH_CONFIG) + SearchVector(
        _plain(F('locator')), weight='A', config=SEARCH_CONFIG
    )
    query = None
    matches = {}
    for index, term in enumerate(terms):
        part = SearchQuery(term, config=SEARCH_CONFIG)
        query = part if query is None else query | part
        matches[f'm{index}'] = Case(When(sv=part, then=Value(1)), default=Value(0))

    base = candidate_fragments(area)
    by_text = (
        base.annotate(sv=vector)
        .annotate(rank=SearchRank(F('sv'), query), **matches)
        .filter(rank__gt=0)
        .select_related('document')
    )

    # Palabras clave cubiertas por fragmento: en el texto o en los términos
    # controlados de sus fichas.
    covered = {}
    fragments = {}
    scores = {}
    for fragment in by_text:
        fragments[fragment.pk] = fragment
        scores[fragment.pk] = float(fragment.rank)
        covered[fragment.pk] = {
            term for index, term in enumerate(terms) if getattr(fragment, f'm{index}')
        }
    for term in terms:
        ids = base.filter(topics__in=_topics_matching_terms(area, [term])).select_related(
            'document'
        )
        for fragment in ids:
            fragments.setdefault(fragment.pk, fragment)
            covered.setdefault(fragment.pk, set()).add(term)
            # Bonificación fija por término controlado (provisional, ver E18).
            scores[fragment.pk] = scores.get(fragment.pk, 0.0) + 0.5

    if not fragments:
        return RetrievalResult(sufficient=False, reason='no_match', keywords=terms)

    minimum = min_coverage()
    coverage = {pk: len(covered[pk]) / len(terms) for pk in fragments}
    ranked = sorted(fragments, key=lambda pk: (-coverage[pk], -scores[pk], pk))
    if coverage[ranked[0]] < minimum:
        # Solo coincidencias parciales (palabras sueltas): mejor abstenerse.
        return RetrievalResult(
            sufficient=False,
            reason='low_coverage',
            keywords=terms,
            best_coverage=round(coverage[ranked[0]], 2),
        )

    selected, used = [], 0
    for pk in ranked:
        fragment = fragments[pk]
        if coverage[pk] < minimum or len(selected) >= max_fragments:
            break
        if used + len(fragment.text) > max_chars and selected:
            break
        selected.append(
            RetrievedFragment(
                id=pk,
                document_title=fragment.document.title,
                document_url=fragment.document.official_url,
                locator=fragment.locator,
                text=fragment.text[:max_chars],
                score=round(scores[pk], 4),
                coverage=round(coverage[pk], 2),
            )
        )
        used += len(fragment.text)

    return RetrievalResult(
        sufficient=True,
        reason='match',
        fragments=selected,
        keywords=terms,
        best_coverage=round(coverage[ranked[0]], 2),
    )
