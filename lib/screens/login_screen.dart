import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    if (!_isRegisterMode) {
      final validation = AuthService.validateCredentials(
        rawEmail: _emailController.text,
        rawPassword: _passwordController.text,
      );

      if (!validation.isValid) {
        setState(() {
          _errorMessage = validation.errorMessage;
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bool success;
      if (_isRegisterMode) {
        success = await widget.authService.register(
          name: _nameController.text,
          rawEmail: _emailController.text,
          rawPassword: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );
      } else {
        success = await widget.authService.login(
          rawEmail: _emailController.text,
          rawPassword: _passwordController.text,
        );
      }

      if (!mounted) return;

      if (success) {
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = 'Correo o contraseña incorrectos';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRegisterMode
              ? 'Crear cuenta - StockFácil'
              : 'Iniciar sesión - StockFácil',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                _isRegisterMode
                    ? 'Registro de cuenta'
                    : 'Bienvenido a StockFácil',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _isRegisterMode
                    ? 'Completa tus datos para administrar el inventario.'
                    : 'Ingresa tus credenciales para administrar el inventario.',
              ),
              const SizedBox(height: 24),
              if (_isRegisterMode) ...[
                TextField(
                  key: const Key('register_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                key: const Key('login_email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'ejemplo@dominio.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('login_password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                enabled: !_isLoading,
              ),
              if (_isRegisterMode) ...[
                const SizedBox(height: 16),
                TextField(
                  key: const Key('register_confirm_password_field'),
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  enabled: !_isLoading,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('login_submit_button'),
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isRegisterMode ? 'Registrar cuenta' : 'Iniciar sesión',
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('toggle_auth_mode_button'),
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                          _errorMessage = null;
                        });
                      },
                child: Text(
                  _isRegisterMode
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : '¿No tienes cuenta? Crear cuenta',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
