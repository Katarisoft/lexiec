from django.contrib import admin

from .models import Profile


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    """Moderación de alias públicos."""

    list_display = ('user', 'display_name')
    search_fields = ('display_name', 'user__email')
    list_select_related = ('user',)
    readonly_fields = ('user',)

    def has_add_permission(self, request):
        return False
