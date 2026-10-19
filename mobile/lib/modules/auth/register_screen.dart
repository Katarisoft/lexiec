import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../common/widgets/error_banner.dart';
import 'auth_controller.dart';
import 'form_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthController _auth = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.register(
      email: _email.text,
      password: _password.text,
      displayName: _displayName.text,
    );
    if (ok) Get.offAllNamed<void>(AppRoutes.home);
  }

  /// Primer error del servidor para un campo, si lo hay.
  String? _serverError(String field) {
    final errors = _auth.fieldErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Obx(() {
              final submitting = _auth.isSubmitting.value;
              final message = _auth.errorMessage.value;
              final hasFieldErrors = _auth.fieldErrors.isNotEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (message != null) ...[
                    ErrorBanner(message: message),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('register-email'),
                    controller: _email,
                    enabled: !submitting,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      errorText: hasFieldErrors ? _serverError('email') : null,
                    ),
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register-password'),
                    controller: _password,
                    enabled: !submitting,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      helperText:
                          'Mínimo 8 caracteres; evita contraseñas comunes.',
                      errorText: hasFieldErrors
                          ? _serverError('password')
                          : null,
                      errorMaxLines: 3,
                    ),
                    validator: FormValidators.newPassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register-display-name'),
                    controller: _displayName,
                    enabled: !submitting,
                    decoration: InputDecoration(
                      labelText: 'Alias público (opcional)',
                      helperText:
                          'Se mostrará en tus comentarios. No uses datos personales.',
                      errorText: hasFieldErrors
                          ? _serverError('display_name')
                          : null,
                    ),
                    validator: FormValidators.displayName,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('register-submit'),
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear cuenta'),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
