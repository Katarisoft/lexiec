from rest_framework.permissions import SAFE_METHODS, BasePermission


class IsAuthorOrReadOnly(BasePermission):
    """Lectura para cualquier sesión; edición y borrado solo para el autor."""

    message = 'Solo el autor puede modificar o eliminar este comentario.'

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        return obj.author_id == request.user.pk
