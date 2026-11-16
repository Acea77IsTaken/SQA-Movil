import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/screens/login_screen.dart';
import 'package:stockfacil_mobile/services/auth_service.dart';

void main() {
  group('Issue #7 - Validación y normalización de autenticación', () {
    test('normaliza espacios exteriores y minúsculas en correo', () {
      final res = AuthService.validateCredentials(
        rawEmail: '   ADMIN@StockFacil.BO   ',
        rawPassword: 'Password123!',
      );

      expect(res.isValid, isTrue);
      expect(res.normalizedEmail, equals('admin@stockfacil.bo'));
    });

    test('conserva la contraseña exactamente como se escribe', () async {
      final authService = AuthService();

      // Contraseña correcta con mayúsculas y caracteres exactos
      final ok = await authService.login(
        rawEmail: 'admin@stockfacil.bo',
        rawPassword: 'Password123!',
      );
      expect(ok, isTrue);

      // Si se añade un espacio o cambia mayúsculas en contraseña, debe fallar
      expect(
        () => authService.login(
          rawEmail: 'admin@stockfacil.bo',
          rawPassword: 'Password123! ',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('muestra mensajes en español para correo vacío o inválido', () {
      final resVacio = AuthService.validateCredentials(
        rawEmail: '   ',
        rawPassword: 'secret',
      );
      expect(resVacio.isValid, isFalse);
      expect(resVacio.errorMessage, 'Ingresa tu correo electrónico');

      final resInvalido = AuthService.validateCredentials(
        rawEmail: 'correo_sin_arroba',
        rawPassword: 'secret',
      );
      expect(resInvalido.isValid, isFalse);
      expect(resInvalido.errorMessage, 'Ingresa un correo electrónico válido');

      final resPassVacia = AuthService.validateCredentials(
        rawEmail: 'admin@stockfacil.bo',
        rawPassword: '',
      );
      expect(resPassVacia.isValid, isFalse);
      expect(resPassVacia.errorMessage, 'Ingresa tu contraseña');
    });

    test('mensaje genérico ante credenciales incorrectas sin revelar existencia', () async {
      final authService = AuthService();
      expect(
        () => authService.login(
          rawEmail: 'noexiste@stockfacil.bo',
          rawPassword: 'Password123!',
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains('Correo o contraseña incorrectos'),
          ),
        ),
      );
    });

    testWidgets(
      'pantalla de login gestiona estado de carga y normaliza correo en el flujo',
      (tester) async {
        bool loginExitoso = false;
        final authService = AuthService();

        await tester.pumpWidget(
          MaterialApp(
            home: LoginScreen(
              authService: authService,
              onLoginSuccess: () {
                loginExitoso = true;
              },
            ),
          ),
        );

        // Intentar envío vacío
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();
        expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);

        // Ingresar correo con espacios exteriores y contraseña válida
        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          '   admin@stockfacil.bo   ',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'Password123!',
        );

        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pump(const Duration(milliseconds: 50));

        // Debe mostrar indicador de progreso
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Esperar a completar
        await tester.pumpAndSettle();
        expect(loginExitoso, isTrue);
      },
    );
  });
}
