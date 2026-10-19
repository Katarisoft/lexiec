from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError, transaction
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .backends import normalize_email
from .models import DISPLAY_NAME_MAX_LENGTH, Profile, validate_display_name

DUPLICATE_EMAIL_MESSAGE = 'Ya existe una cuenta con este correo.'


def display_name_field():
    return serializers.CharField(
        max_length=DISPLAY_NAME_MAX_LENGTH,
        required=False,
        allow_blank=True,
        validators=[validate_display_name],
    )


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=150)
    password = serializers.CharField(write_only=True, trim_whitespace=False)
    display_name = display_name_field()

    def validate_email(self, value):
        email = normalize_email(value)
        if get_user_model().objects.filter(username=email).exists():
            raise serializers.ValidationError(DUPLICATE_EMAIL_MESSAGE)
        return email

    def validate(self, attrs):
        # Los validadores de Django comparan la contraseña con el correo.
        candidate = get_user_model()(username=attrs['email'], email=attrs['email'])
        try:
            validate_password(attrs['password'], user=candidate)
        except DjangoValidationError as error:
            raise serializers.ValidationError({'password': list(error.messages)})
        return attrs

    def create(self, validated_data):
        email = validated_data['email']
        try:
            with transaction.atomic():
                user = get_user_model().objects.create_user(
                    username=email, email=email, password=validated_data['password']
                )
                Profile.objects.create(
                    user=user, display_name=validated_data.get('display_name', '')
                )
                return user
        except IntegrityError:
            # Registro simultáneo con el mismo correo.
            raise serializers.ValidationError({'email': [DUPLICATE_EMAIL_MESSAGE]})


class UserSerializer(serializers.ModelSerializer):
    display_name = serializers.SerializerMethodField()

    class Meta:
        model = get_user_model()
        fields = ('id', 'email', 'display_name', 'date_joined')
        read_only_fields = fields

    def get_display_name(self, user):
        profile = getattr(user, 'profile', None)
        return profile.display_name if profile else ''


class ProfileUpdateSerializer(serializers.Serializer):
    display_name = display_name_field()


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Login con `email` y `password`; delega en EmailBackend."""

    username_field = 'email'

    def validate(self, attrs):
        attrs['email'] = normalize_email(attrs.get('email'))
        return super().validate(attrs)


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()
