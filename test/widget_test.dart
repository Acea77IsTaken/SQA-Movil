import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/app.dart';

void main() {
  testWidgets('muestra la marca y permite recorrer las tres secciones', (
    tester,
  ) async {
    await tester.pumpWidget(const StockFacilApp(requireAuth: false));
    expect(find.text('StockFácil'), findsOneWidget);
    for (final icon in [
      Icons.warning_amber_outlined,
      Icons.history,
      Icons.inventory_2_outlined,
    ]) {
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Productos'), findsNWidgets(2));
  });
}
