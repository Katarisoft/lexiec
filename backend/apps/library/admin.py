from django.contrib import admin

from .models import LegalArea, SourceDocument, SourceFragment, TopicCard

REVIEW_FIELDSET = (
    'Revisión humana',
    {'fields': ('review_status', 'reviewed_by', 'reviewed_at', 'review_notes')},
)
TIMESTAMPS_FIELDSET = (
    'Registro',
    {'fields': ('created_at', 'updated_at'), 'classes': ('collapse',)},
)
REVIEWER_CHOICES = {'is_staff': True}


class ReviewerAdminMixin:
    """Limita el revisor a cuentas con acceso al panel de administración."""

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == 'reviewed_by':
            kwargs['limit_choices_to'] = REVIEWER_CHOICES
        return super().formfield_for_foreignkey(db_field, request, **kwargs)


@admin.register(LegalArea)
class LegalAreaAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'order')
    search_fields = ('name', 'slug')
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = ('created_at', 'updated_at')


class SourceFragmentInline(ReviewerAdminMixin, admin.StackedInline):
    model = SourceFragment
    extra = 0
    fields = ('locator', 'order', 'text', 'review_status', 'reviewed_by', 'reviewed_at')
    show_change_link = True


@admin.register(SourceDocument)
class SourceDocumentAdmin(ReviewerAdminMixin, admin.ModelAdmin):
    list_display = (
        'title',
        'institution',
        'version_label',
        'review_status',
        'publication_status',
        'validity_status',
        'has_limitations',
    )
    list_filter = ('review_status', 'publication_status', 'validity_status', 'institution')
    search_fields = ('title', 'institution', 'publication_reference')
    readonly_fields = ('created_at', 'updated_at')
    inlines = [SourceFragmentInline]
    fieldsets = (
        (
            'Documento',
            {
                'fields': (
                    'institution',
                    'title',
                    'official_url',
                    'publication_reference',
                    'publication_date',
                    'version_label',
                    'retrieved_at',
                    'text_hash',
                )
            },
        ),
        REVIEW_FIELDSET,
        ('Publicación en la app', {'fields': ('publication_status',)}),
        (
            'Vigencia y limitaciones',
            {
                'fields': (
                    'validity_status',
                    'validity_checked_at',
                    'validity_note',
                    'limitations',
                )
            },
        ),
        TIMESTAMPS_FIELDSET,
    )

    @admin.display(boolean=True, description='limitaciones')
    def has_limitations(self, obj):
        return bool(obj.limitations.strip())


@admin.register(SourceFragment)
class SourceFragmentAdmin(ReviewerAdminMixin, admin.ModelAdmin):
    list_display = ('locator', 'document', 'order', 'review_status')
    list_filter = ('review_status', 'document__publication_status')
    search_fields = ('locator', 'text', 'document__title')
    list_select_related = ('document',)
    autocomplete_fields = ('document',)
    readonly_fields = ('created_at', 'updated_at')
    fieldsets = (
        ('Fragmento', {'fields': ('document', 'locator', 'order', 'text')}),
        REVIEW_FIELDSET,
        TIMESTAMPS_FIELDSET,
    )


@admin.register(TopicCard)
class TopicCardAdmin(ReviewerAdminMixin, admin.ModelAdmin):
    list_display = ('title', 'area', 'review_status', 'publication_status')
    list_filter = ('area', 'review_status', 'publication_status')
    search_fields = ('title', 'slug', 'summary')
    list_select_related = ('area',)
    prepopulated_fields = {'slug': ('title',)}
    filter_horizontal = ('fragments',)
    readonly_fields = ('created_at', 'updated_at')
    fieldsets = (
        ('Ficha', {'fields': ('area', 'title', 'slug', 'summary', 'search_terms')}),
        ('Respaldo documental', {'fields': ('fragments',)}),
        REVIEW_FIELDSET,
        ('Publicación en la app', {'fields': ('publication_status',)}),
        TIMESTAMPS_FIELDSET,
    )
