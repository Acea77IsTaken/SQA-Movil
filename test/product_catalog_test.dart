import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/models/product.dart';
import 'package:stockfacil_mobile/screens/product_list_screen.dart';
import 'package:stockfacil_mobile/services/inventory_repository.dart';

void main() {
  group('Issue #2 - Catálogo y búsqueda de productos', () {
    test('clasifica correctamente los tres estados de stock', () {
      const pAgotado = Product(
        id: '1',
        name: 'Producto A',
        sku: 'SKU-A',
        category: 'Cat',
        price: 10.0,
        stock: 0,
        minStock: 5,
      );
      expect(pAgotado.status, StockStatus.agotado);
      expect(pAgotado.status.label, 'Agotado');

      const pBajo = Product(
        id: '2',
        name: 'Producto B',
        sku: 'SKU-B',
        category: 'Cat',
        price: 10.0,
        stock: 5,
        minStock: 5,
      );
      expect(pBajo.status, StockStatus.stockBajo);
      expect(pBajo.status.label, 'Stock bajo');

      const pDisponible = Product(
        id: '3',
        name: 'Producto C',
        sku: 'SKU-C',
        category: 'Cat',
        price: 10.0,
        stock: 15,
        minStock: 5,
      );
      expect(pDisponible.status, StockStatus.disponible);
      expect(pDisponible.status.label, 'Disponible');
    });

    testWidgets(
      'muestra datos completos y filtra por nombre y SKU con opcion de limpiar',
      (tester) async {
        final repo = InventoryRepository(
          initialProducts: [
            const Product(
              id: '1',
              name: 'Arroz blanco 1kg',
              sku: 'AB-001',
              category: 'Abarrotes',
              price: 8.50,
              stock: 25,
              minStock: 10,
            ),
            const Product(
              id: '2',
              name: 'Aceite vegetal 900ml',
              sku: 'AV-002',
              category: 'Abarrotes',
              price: 13.00,
              stock: 0,
              minStock: 5,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProductListScreen(repository: repo),
            ),
          ),
        );

        // Verificar datos iniciales y formato de precio en Bs
        expect(find.text('Arroz blanco 1kg'), findsOneWidget);
        expect(find.text('SKU: AB-001'), findsOneWidget);
        expect(find.text('Abarrotes'), findsNWidgets(2));
        expect(find.text('Bs. 8.50'), findsOneWidget);
        expect(find.text('Disponible'), findsOneWidget);
        expect(find.text('Agotado'), findsOneWidget);

        // Buscar por nombre
        await tester.enterText(
          find.byKey(const Key('product_search_field')),
          'Arroz',
        );
        await tester.pumpAndSettle();
        expect(find.text('Arroz blanco 1kg'), findsOneWidget);
        expect(find.text('Aceite vegetal 900ml'), findsNothing);

        // Limpiar búsqueda
        await tester.tap(find.byKey(const Key('clear_search_button')));
        await tester.pumpAndSettle();
        expect(find.text('Arroz blanco 1kg'), findsOneWidget);
        expect(find.text('Aceite vegetal 900ml'), findsOneWidget);

        // Buscar por SKU
        await tester.enterText(
          find.byKey(const Key('product_search_field')),
          'av-002',
        );
        await tester.pumpAndSettle();
        expect(find.text('Aceite vegetal 900ml'), findsOneWidget);
        expect(find.text('Arroz blanco 1kg'), findsNothing);

        // Búsqueda sin coincidencias
        await tester.enterText(
          find.byKey(const Key('product_search_field')),
          'InexistenteXYZ',
        );
        await tester.pumpAndSettle();
        expect(
          find.text('No se encontraron productos para la búsqueda'),
          findsOneWidget,
        );
      },
    );

    testWidgets('distingue catálogo vacío con mensaje específico', (
      tester,
    ) async {
      final repoVacio = InventoryRepository(initialProducts: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductListScreen(repository: repoVacio),
          ),
        ),
      );

      expect(find.text('El catálogo de productos está vacío'), findsOneWidget);
    });
  });
}
