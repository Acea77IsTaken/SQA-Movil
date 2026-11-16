import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/models/inventory_movement.dart';
import 'package:stockfacil_mobile/screens/register_product_screen.dart';
import 'package:stockfacil_mobile/services/inventory_repository.dart';

void main() {
  group('Issue #3 - Registro de productos con validaciones y trazabilidad', () {
    test('registra producto y crea movimiento inicial atómicamente si stock > 0', () {
      final repo = InventoryRepository(initialProducts: [], initialMovements: []);

      final prod = repo.registerProduct(
        name: 'Fideos 500g',
        rawSku: '  fid-500  ',
        category: 'Abarrotes',
        price: 5.50,
        initialStock: 15,
        minStock: 5,
        responsible: 'Encargado1',
      );

      expect(prod.sku, 'FID-500'); // normalizado a mayúsculas
      expect(prod.stock, 15);
      expect(repo.getAllActiveProducts().length, 1);

      // Movimiento atómico creado
      final movements = repo.getAllMovements();
      expect(movements.length, 1);
      expect(movements.first.type, MovementType.entrada);
      expect(movements.first.quantity, 15);
      expect(movements.first.previousStock, 0);
      expect(movements.first.newStock, 15);
      expect(movements.first.observation, 'Inventario inicial');
    });

    test('no crea movimiento cuando el stock inicial es cero', () {
      final repo = InventoryRepository(initialProducts: [], initialMovements: []);

      final prod = repo.registerProduct(
        name: 'Sal de mesa 1kg',
        rawSku: 'SAL-001',
        category: 'Abarrotes',
        price: 2.00,
        initialStock: 0,
        minStock: 5,
      );

      expect(prod.stock, 0);
      expect(repo.getAllMovements(), isEmpty);
    });

    test('rechaza SKU duplicado con diferente uso de mayúsculas y minúsculas', () {
      final repo = InventoryRepository();

      expect(
        () => repo.registerProduct(
          name: 'Otro Arroz',
          rawSku: 'ab-001', // Ya existe 'AB-001'
          category: 'Abarrotes',
          price: 10.0,
          initialStock: 5,
          minStock: 2,
        ),
        throwsA(isA<InventoryValidationException>()),
      );
    });

    test('rechaza precio negativo y stock negativo', () {
      final repo = InventoryRepository(initialProducts: []);

      expect(
        () => repo.registerProduct(
          name: 'Producto Inválido',
          rawSku: 'INV-001',
          category: 'Abarrotes',
          price: -5.0,
          initialStock: 10,
          minStock: 2,
        ),
        throwsA(isA<InventoryValidationException>()),
      );

      expect(
        () => repo.registerProduct(
          name: 'Producto Inválido 2',
          rawSku: 'INV-002',
          category: 'Abarrotes',
          price: 10.0,
          initialStock: -1,
          minStock: 2,
        ),
        throwsA(isA<InventoryValidationException>()),
      );
    });

    testWidgets(
      'pantalla de registro valida campos en español y conserva lo ingresado ante error',
      (tester) async {
        final repo = InventoryRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: RegisterProductScreen(repository: repo),
          ),
        );

        // Intentar registrar sin datos
        await tester.tap(find.byKey(const Key('register_product_submit_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('El nombre del producto no puede estar vacío'),
          findsOneWidget,
        );

        // Llenar con SKU duplicado existente ('AB-001')
        await tester.enterText(
          find.byKey(const Key('product_name_field')),
          'Nuevo Arroz Premium',
        );
        await tester.enterText(
          find.byKey(const Key('product_sku_field')),
          'ab-001',
        );
        await tester.enterText(
          find.byKey(const Key('product_price_field')),
          '15.50',
        );
        await tester.enterText(
          find.byKey(const Key('product_initial_stock_field')),
          '10',
        );
        await tester.enterText(
          find.byKey(const Key('product_min_stock_field')),
          '3',
        );

        await tester.ensureVisible(
          find.byKey(const Key('register_product_submit_button')),
        );
        await tester.tap(find.byKey(const Key('register_product_submit_button')));
        await tester.pumpAndSettle();

        // Debe mostrar error de duplicado en español
        expect(
          find.textContaining('ya se encuentra registrado'),
          findsOneWidget,
        );

        // Debe conservar los datos ingresados en los campos
        expect(find.text('Nuevo Arroz Premium'), findsOneWidget);
        expect(find.text('15.50'), findsOneWidget);
      },
    );
  });
}
