import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../common/widgets/academic_notice.dart';
import '../common/widgets/error_banner.dart';
import 'auth_controller.dart';
import 'form_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _auth = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.login(email: _email.text, password: _password.text);
    if (ok) Get.offAllNamed<void>(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Obx(() {
              final submitting = _auth.isSubmitting.value;
              final message = _auth.errorMessage.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'LexiEC',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (message != null) ...[
                    ErrorBanner(message: message),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('login-email'),
                    controller: _email,
                    enabled: !submitting,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('login-password'),
                    controller: _password,
                    enabled: !submitting,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: FormValidators.requiredPassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('login-submit'),
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () {
                            _auth.clearErrors();
                            Get.toNamed<void>(AppRoutes.register);
                          },
                    child: const Text('Crear una cuenta'),
                  ),
                  const SizedBox(height: 24),
                  const AcademicNotice(),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
