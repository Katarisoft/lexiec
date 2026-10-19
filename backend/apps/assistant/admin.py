from django.contrib import admin

from .models import AIUsage


@admin.register(AIUsage)
class AIUsageAdmin(admin.ModelAdmin):
    """Consulta del registro de consumo (sin texto de consultas).

    Solo lectura: las altas y conciliaciones se hacen con el servicio de
    presupuesto o con `manage.py ai_budget`, para respetar el bloqueo.
    Las consultas privadas no se registran en el Admin.
    """

    list_display = (
        'id',
        'created_at',
        'purpose',
        'status',
        'model_name',
        'reserved_usd',
        'actual_usd',
        'input_tokens',
        'output_tokens',
    )
    list_filter = ('status', 'purpose', 'model_name')
    readonly_fields = [field.name for field in AIUsage._meta.fields]
    exclude = ('user', 'consultation')

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
