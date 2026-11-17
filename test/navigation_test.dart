import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/app.dart';

void main() {
  group('Issue #8 - Robustez de navegacion y prevencion de cierres', () {
    testWidgets(
      'ejecuta 20 cambios rapidos de pantalla sin excepciones ni cierres',
      (tester) async {
        await tester.pumpWidget(const StockFacilApp(requireAuth: false));
        expect(find.text('StockFácil'), findsOneWidget);

        final icons = [
          Icons.inventory_2_outlined,
          Icons.warning_amber_outlined,
          Icons.history,
        ];

        // Ejecutar 20 cambios continuos y rapidos
        for (int i = 0; i < 20; i++) {
          final targetIcon = icons[i % icons.length];
          await tester.tap(find.byIcon(targetIcon));
          await tester.pump(const Duration(milliseconds: 10));
          expect(tester.takeException(), isNull);
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('gestiona el boton Volver para volver a la pestana inicial', (
      tester,
    ) async {
      await tester.pumpWidget(const StockFacilApp(requireAuth: false));

      // Ir a Historial
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('Historial'), findsNWidgets(2));

      // Simular accion del sistema de retroceder (pop)
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Debe retornar a Productos sin cerrar la aplicacion
      expect(find.text('Productos'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'soporta cargas asincronas pendientes durante el cambio de pantalla',
      (tester) async {
        await tester.pumpWidget(const StockFacilApp(requireAuth: false));
        final state = tester.state<InventoryHomeState>(find.byType(InventoryHome));

        // Iniciar carga asincrona simulada
        state.simulateAsyncLoad();
        await tester.pump();

        // Cambiar rapidamente de pantalla mientras la carga sigue pendiente
        await tester.tap(find.byIcon(Icons.warning_amber_outlined));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.tap(find.byIcon(Icons.history));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
