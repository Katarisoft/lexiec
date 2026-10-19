from django.contrib.auth import get_user_model
from rest_framework import exceptions, generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.settings import api_settings as jwt_settings
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import Profile
from .serializers import (
    EmailTokenObtainPairSerializer,
    LogoutSerializer,
    ProfileUpdateSerializer,
    RegisterSerializer,
    UserSerializer,
)


class InvalidRefreshToken(exceptions.APIException):
    status_code = status.HTTP_400_BAD_REQUEST
    default_code = 'invalid_refresh_token'
    default_detail = 'Token de actualización inválido o expirado.'


class RegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = RegisterSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'register'

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class EmailTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'login'


class MeView(APIView):
    """Perfil propio: consulta y actualización del alias público."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = ProfileUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if 'display_name' in serializer.validated_data:
            Profile.objects.update_or_create(
                user=request.user,
                defaults={'display_name': serializer.validated_data['display_name']},
            )
        user = get_user_model().objects.select_related('profile').get(pk=request.user.pk)
        return Response(UserSerializer(user).data)


class LogoutView(APIView):
    """Invalida el refresh token de la sesión.

    El access token ya emitido sigue siendo válido hasta su caducidad
    (vida corta, ver SIMPLE_JWT); el cliente debe descartarlo.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            token = RefreshToken(serializer.validated_data['refresh'])
        except TokenError:
            raise InvalidRefreshToken()

        # Un usuario no puede invalidar la sesión de otro.
        if str(token.get(jwt_settings.USER_ID_CLAIM)) != str(request.user.pk):
            raise InvalidRefreshToken()

        token.blacklist()
        return Response(status=status.HTTP_204_NO_CONTENT)
