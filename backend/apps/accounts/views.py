from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.settings import api_settings as jwt_settings
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import (
    EmailTokenObtainPairSerializer,
    LogoutSerializer,
    RegisterSerializer,
    UserSerializer,
)

INVALID_REFRESH_MESSAGE = 'Token de actualización inválido o expirado.'


class RegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class EmailTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer


class MeView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


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
            return Response({'detail': INVALID_REFRESH_MESSAGE}, status=status.HTTP_400_BAD_REQUEST)

        # Un usuario no puede invalidar la sesión de otro.
        if str(token.get(jwt_settings.USER_ID_CLAIM)) != str(request.user.pk):
            return Response({'detail': INVALID_REFRESH_MESSAGE}, status=status.HTTP_400_BAD_REQUEST)

        token.blacklist()
        return Response(status=status.HTTP_204_NO_CONTENT)
