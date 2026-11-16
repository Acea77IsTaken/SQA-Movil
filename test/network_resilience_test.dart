import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/services/network_exceptions.dart';
import 'package:stockfacil_mobile/widgets/connection_error_banner.dart';

void main() {
  group('Issue #9 - Manejo de fallos de conexión y reintento', () {
    test('clasifica y genera mensajes específicos en español', () {
      final noConn = NetworkException.noConnection();
      expect(noConn.type, NetworkErrorType.noConnection);
      expect(
        noConn.message,
        'Sin conexión a la red. Verifica tu conexión e inténtalo de nuevo.',
      );

      final timeout = NetworkException.timeout();
      expect(timeout.type, NetworkErrorType.timeout);
      expect(
        timeout.message,
        'Tiempo de espera agotado al conectar con el servidor.',
      );

      final serverErr = NetworkException.serverError(503);
      expect(serverErr.type, NetworkErrorType.serverError);
      expect(serverErr.message, contains('Código 503'));

      final uncertain = NetworkException.uncertainWrite();
      expect(uncertain.type, NetworkErrorType.uncertainWrite);
      expect(
        uncertain.message,
        contains('No se pudo confirmar si la operación fue guardada'),
      );
    });

    testWidgets(
      'muestra aviso visible con Reintentar y recupera la operación',
      (tester) async {
        bool reintentoEjecutado = false;
        NetworkException? errorActual = NetworkException.noConnection();

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const TextField(
                          key: Key('sample_input_field'),
                          decoration: InputDecoration(labelText: 'Dato escrito'),
                        ),
                        if (errorActual != null)
                          ConnectionErrorBanner(
                            exception: errorActual!,
                            onRetry: () {
                              setState(() {
                                reintentoEjecutado = true;
                                errorActual = null; // recuperación
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Escribir en el formulario
        await tester.enterText(
          find.byKey(const Key('sample_input_field')),
          'Texto no perdido',
        );

        // Verificar presencia del mensaje y botón
        expect(
          find.text(
            'Sin conexión a la red. Verifica tu conexión e inténtalo de nuevo.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('connection_retry_button')), findsOneWidget);

        // Pulsar Reintentar
        await tester.tap(find.byKey(const Key('connection_retry_button')));
        await tester.pumpAndSettle();

        // Verificar que el reintento se ejecutó y se eliminó el aviso obsoleto
        expect(reintentoEjecutado, isTrue);
        expect(find.byType(ConnectionErrorBanner), findsNothing);

        // Verificar que el texto del formulario se conservó
        expect(find.text('Texto no perdido'), findsOneWidget);
      },
    );
  });
}
