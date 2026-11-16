import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/models/inventory_movement.dart';
import 'package:stockfacil_mobile/models/product.dart';
import 'package:stockfacil_mobile/screens/register_movement_screen.dart';
import 'package:stockfacil_mobile/services/inventory_repository.dart';

void main() {
  group('Issue #4 - Movimientos de inventario sin stock negativo', () {
    test('stock 10 + entrada 5 = 15', () {
      final repo = InventoryRepository(
        initialProducts: [
          const Product(
            id: '1',
            name: 'Producto Prueba',
            sku: 'PRU-001',
            category: 'Abarrotes',
            price: 10.0,
            stock: 10,
            minStock: 2,
          ),
        ],
        initialMovements: [],
      );

      final mov = repo.registerMovement(
        productId: '1',
        type: MovementType.entrada,
        quantity: 5,
        observation: 'Compra adicional',
      );

      expect(mov.previousStock, 10);
      expect(mov.newStock, 15);
      expect(mov.quantity, 5);
      expect(repo.findById('1')!.stock, 15);
      expect(repo.getAllMovements().length, 1);
    });

    test('stock 10 - salida 4 = 6', () {
      final repo = InventoryRepository(
        initialProducts: [
          const Product(
            id: '1',
            name: 'Producto Prueba',
            sku: 'PRU-001',
            category: 'Abarrotes',
            price: 10.0,
            stock: 10,
            minStock: 2,
          ),
        ],
        initialMovements: [],
      );

      final mov = repo.registerMovement(
        productId: '1',
        type: MovementType.salida,
        quantity: 4,
        observation: 'Venta',
      );

      expect(mov.previousStock, 10);
      expect(mov.newStock, 6);
      expect(mov.quantity, 4);
      expect(repo.findById('1')!.stock, 6);
      expect(repo.getAllMovements().length, 1);
    });

    test(
      'salida 11 con stock 10 se rechaza, mantiene saldo y no añade historial',
      () {
        final repo = InventoryRepository(
          initialProducts: [
            const Product(
              id: '1',
              name: 'Producto Prueba',
              sku: 'PRU-001',
              category: 'Abarrotes',
              price: 10.0,
              stock: 10,
              minStock: 2,
            ),
          ],
          initialMovements: [],
        );

        expect(
          () => repo.registerMovement(
            productId: '1',
            type: MovementType.salida,
            quantity: 11,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is InventoryValidationException &&
                  e.message.contains('Saldo insuficiente'),
            ),
          ),
        );

        // El stock debe permanecer intacto en 10
        expect(repo.findById('1')!.stock, 10);
        // No se debe registrar ningún movimiento
        expect(repo.getAllMovements(), isEmpty);
      },
    );

    test('rechaza movimientos de productos inactivos y cantidad <= 0', () {
      final repo = InventoryRepository(
        initialProducts: [
          const Product(
            id: 'inactive-1',
            name: 'Inactivo',
            sku: 'INA-001',
            category: 'Abarrotes',
            price: 5.0,
            stock: 10,
            minStock: 2,
            isActive: false,
          ),
        ],
        initialMovements: [],
      );

      expect(
        () => repo.registerMovement(
          productId: 'inactive-1',
          type: MovementType.entrada,
          quantity: 5,
        ),
        throwsA(
          predicate(
            (e) =>
                e is InventoryValidationException &&
                e.message.contains('productos inactivos'),
          ),
        ),
      );

      expect(
        () => repo.registerMovement(
          productId: 'inactive-1',
          type: MovementType.entrada,
          quantity: 0,
        ),
        throwsA(isA<InventoryValidationException>()),
      );
    });

    testWidgets(
      'pantalla de movimiento rechaza cantidad inválida y salida superior a existencias',
      (tester) async {
        final repo = InventoryRepository(
          initialProducts: [
            const Product(
              id: 'prod-10',
              name: 'Arroz Especial',
              sku: 'AE-10',
              category: 'Abarrotes',
              price: 10.0,
              stock: 10,
              minStock: 2,
            ),
          ],
          initialMovements: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RegisterMovementScreen(
              repository: repo,
              initialProductId: 'prod-10',
            ),
          ),
        );

        // Seleccionar tipo Salida
        await tester.tap(find.text('Salida'));
        await tester.pumpAndSettle();

        // Ingresar cantidad superior al saldo (15)
        await tester.enterText(
          find.byKey(const Key('movement_quantity_field')),
          '15',
        );

        await tester.ensureVisible(
          find.byKey(const Key('movement_submit_button')),
        );
        await tester.tap(find.byKey(const Key('movement_submit_button')));
        await tester.pumpAndSettle();

        // Verificar mensaje de error en español
        expect(find.textContaining('Saldo insuficiente'), findsOneWidget);

        // El stock en el repositorio no cambió
        expect(repo.findById('prod-10')!.stock, 10);
      },
    );
  });
}
