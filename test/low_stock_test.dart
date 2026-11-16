import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/models/product.dart';
import 'package:stockfacil_mobile/screens/low_stock_screen.dart';
import 'package:stockfacil_mobile/services/inventory_repository.dart';

void main() {
  group('Issue #5 - Consulta de productos con stock bajo o agotado', () {
    test(
      'filtra estrictamente productos activos con stock <= minStock y clasifica',
      () {
        final repo = InventoryRepository(
          initialProducts: [
            const Product(
              id: '1',
              name: 'Agotado 1',
              sku: 'AG-01',
              category: 'Cat',
              price: 10,
              stock: 0,
              minStock: 5,
            ),
            const Product(
              id: '2',
              name: 'Bajo 2',
              sku: 'BJ-02',
              category: 'Cat',
              price: 10,
              stock: 3,
              minStock: 5,
            ),
            const Product(
              id: '3',
              name: 'Exacto Minimo',
              sku: 'EX-03',
              category: 'Cat',
              price: 10,
              stock: 5, // stock == minStock
              minStock: 5,
            ),
            const Product(
              id: '4',
              name: 'Abastecido',
              sku: 'AB-04',
              category: 'Cat',
              price: 10,
              stock: 20, // stock > minStock
              minStock: 5,
            ),
            const Product(
              id: '5',
              name: 'Inactivo Bajo',
              sku: 'IN-05',
              category: 'Cat',
              price: 10,
              stock: 1,
              minStock: 5,
              isActive: false, // inactivo
            ),
          ],
        );

        final result = repo.getLowOrOutOfStockProducts();

        // Debe incluir 1, 2 y 3. No debe incluir 4 (abastecido) ni 5 (inactivo)
        expect(result.length, 3);
        expect(result.any((p) => p.id == '1'), isTrue);
        expect(result.any((p) => p.id == '2'), isTrue);
        expect(result.any((p) => p.id == '3'), isTrue);
        expect(result.any((p) => p.id == '4'), isFalse);
        expect(result.any((p) => p.id == '5'), isFalse);
      },
    );

    testWidgets(
      'pantalla muestra datos, badges correspondientes y boton de reponer',
      (tester) async {
        final repo = InventoryRepository(
          initialProducts: [
            const Product(
              id: '1',
              name: 'Aceite vegetal',
              sku: 'AV-01',
              category: 'Abarrotes',
              price: 12.0,
              stock: 0,
              minStock: 5,
            ),
            const Product(
              id: '2',
              name: 'Leche entera',
              sku: 'LE-02',
              category: 'Lácteos',
              price: 7.0,
              stock: 4,
              minStock: 5,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LowStockScreen(repository: repo),
            ),
          ),
        );

        expect(find.text('Aceite vegetal'), findsOneWidget);
        expect(find.text('Agotado'), findsOneWidget);
        expect(find.text('Disponible: 0 un.'), findsOneWidget);

        expect(find.text('Leche entera'), findsOneWidget);
        expect(find.text('Stock bajo'), findsOneWidget);
        expect(find.text('Disponible: 4 un.'), findsOneWidget);

        expect(find.byKey(const Key('restock_button_1')), findsOneWidget);
      },
    );

    testWidgets('muestra estado vacio cuando ningun producto tiene stock bajo', (
      tester,
    ) async {
      final repo = InventoryRepository(
        initialProducts: [
          const Product(
            id: '1',
            name: 'Producto Abastecido',
            sku: 'PA-01',
            category: 'Cat',
            price: 10,
            stock: 50,
            minStock: 10,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LowStockScreen(repository: repo),
          ),
        ),
      );

      expect(
        find.text('No hay productos con stock bajo o agotado'),
        findsOneWidget,
      );
    });
  });
}
