class AuthValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? normalizedEmail;

  const AuthValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.normalizedEmail,
  });

  factory AuthValidationResult.valid(String normalizedEmail) =>
      AuthValidationResult._(isValid: true, normalizedEmail: normalizedEmail);

  factory AuthValidationResult.error(String message) =>
      AuthValidationResult._(isValid: false, errorMessage: message);
}

class AuthService {
  // Demo local user credentials
  static const String demoEmail = 'admin@stockfacil.bo';
  static const String demoPassword = 'Password123!';

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static AuthValidationResult validateCredentials({
    required String rawEmail,
    required String rawPassword,
  }) {
    final trimmedEmail = rawEmail.trim();

    if (trimmedEmail.isEmpty) {
      return AuthValidationResult.error('Ingresa tu correo electrónico');
    }

    if (!_emailRegExp.hasMatch(trimmedEmail)) {
      return AuthValidationResult.error('Ingresa un correo electrónico válido');
    }

    if (rawPassword.isEmpty) {
      return AuthValidationResult.error('Ingresa tu contraseña');
    }

    final normalizedEmail = trimmedEmail.toLowerCase();
    return AuthValidationResult.valid(normalizedEmail);
  }

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  Future<bool> login({
    required String rawEmail,
    required String rawPassword,
  }) async {
    if (_isAuthenticating) {
      return false;
    }

    _isAuthenticating = true;
    try {
      final validation = validateCredentials(
        rawEmail: rawEmail,
        rawPassword: rawPassword,
      );

      if (!validation.isValid) {
        throw Exception(validation.errorMessage);
      }

      // Simulate async network/disk check
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Password comparison preserves exact characters
      final emailMatches = validation.normalizedEmail == demoEmail.toLowerCase();
      final passwordMatches = rawPassword == demoPassword;

      if (!emailMatches || !passwordMatches) {
        throw Exception('Correo o contraseña incorrectos');
      }

      return true;
    } finally {
      _isAuthenticating = false;
    }
  }
}
