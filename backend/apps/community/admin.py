from django.contrib import admin

from .models import Comment


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    """Moderación: consultar y eliminar comentarios.

    Los comentarios solo se crean desde la app y el texto del autor no se
    edita desde el panel.
    """

    list_display = ('id', 'topic', 'author', 'short_text', 'created_at', 'updated_at')
    list_filter = ('topic__area', 'created_at')
    search_fields = ('text', 'author__email', 'topic__title')
    list_select_related = ('topic', 'author')
    readonly_fields = ('topic', 'author', 'text', 'created_at', 'updated_at')

    @admin.display(description='texto')
    def short_text(self, obj):
        return obj.text if len(obj.text) <= 80 else f'{obj.text[:77]}...'

    def has_add_permission(self, request):
        return False
