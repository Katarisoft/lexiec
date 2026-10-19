from rest_framework import serializers

from apps.accounts.models import public_name

from .models import COMMENT_MAX_LENGTH, Comment


class CommentSerializer(serializers.ModelSerializer):
    """El autor y la ficha los asigna el servidor; nunca se leen del cliente."""

    text = serializers.CharField(max_length=COMMENT_MAX_LENGTH, trim_whitespace=True)
    author = serializers.SerializerMethodField()
    is_mine = serializers.SerializerMethodField()
    edited = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = ('id', 'text', 'author', 'is_mine', 'created_at', 'updated_at', 'edited')
        read_only_fields = ('id', 'created_at', 'updated_at')

    def get_author(self, comment):
        return {'display_name': public_name(comment.author)}

    def get_is_mine(self, comment):
        request = self.context.get('request')
        return bool(request and comment.author_id == request.user.pk)

    def get_edited(self, comment):
        # Tolerancia para la diferencia entre auto_now_add y auto_now al crear.
        return (comment.updated_at - comment.created_at).total_seconds() > 1
