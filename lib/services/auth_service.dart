import 'network_exceptions.dart';
import 'web_api_service.dart';

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
  static const String demoEmail = 'admin@stockfacil.bo';
  static const String demoPassword = 'Password123!';

  // Credenciales oficiales del seeder del sistema web Laravel
  static const String webAdminEmail = 'admin@stockfacil.test';
  static const String webAdminPassword = 'StockFacil2026!';

  final WebApiService? apiService;

  AuthService({this.apiService});

  final Map<String, ({String name, String password})> _users = {
    demoEmail: (name: 'Administrador Móvil', password: demoPassword),
    webAdminEmail: (name: 'Administrador', password: webAdminPassword),
  };

  String? _currentUserEmail;
  String? _currentUserName;

  String? get currentUserEmail => _currentUserEmail;
  String get currentUserName => _currentUserName ?? 'Administrador';
  bool get isLoggedIn => _currentUserEmail != null;

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

      final normalized = validation.normalizedEmail!;

      // Si hay servicio API configurado, autenticar contra el servidor web Laravel primero
      if (apiService != null) {
        try {
          final res = await apiService!.login(
            email: normalized,
            password: rawPassword,
          );
          final user = res['user'] as Map<String, dynamic>?;
          _currentUserEmail = (user?['email'] ?? normalized).toString();
          _currentUserName = (user?['name'] ?? 'Administrador').toString();
          return true;
        } on NetworkException {
          // Si no hay conexión al servidor web, permitir respaldo local
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      final account = _users[normalized];

      if (account == null || account.password != rawPassword) {
        throw Exception('Correo o contraseña incorrectos');
      }

      _currentUserEmail = normalized;
      _currentUserName = account.name;
      return true;
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<bool> register({
    required String name,
    required String rawEmail,
    required String rawPassword,
    required String passwordConfirmation,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Ingresa tu nombre completo');
    }

    final validation = validateCredentials(
      rawEmail: rawEmail,
      rawPassword: rawPassword,
    );
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    if (rawPassword.length < 8) {
      throw Exception('La contraseña debe tener al menos 8 caracteres');
    }

    if (rawPassword != passwordConfirmation) {
      throw Exception('La confirmación de la contraseña no coincide');
    }

    final normalized = validation.normalizedEmail!;

    if (apiService != null) {
      try {
        final res = await apiService!.register(
          name: cleanName,
          email: normalized,
          password: rawPassword,
          passwordConfirmation: passwordConfirmation,
        );
        final user = res['user'] as Map<String, dynamic>?;
        _currentUserEmail = (user?['email'] ?? normalized).toString();
        _currentUserName = (user?['name'] ?? cleanName).toString();
        return true;
      } on NetworkException {
        // Respaldo local si no hay red
      }
    }

    if (_users.containsKey(normalized)) {
      throw Exception('Este correo electrónico ya está registrado');
    }

    _users[normalized] = (name: cleanName, password: rawPassword);
    _currentUserEmail = normalized;
    _currentUserName = cleanName;
    return true;
  }

  void logout() {
    _currentUserEmail = null;
    _currentUserName = null;
    apiService?.logout();
  }
}
