import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/models/inventory_movement.dart';
import 'package:stockfacil_mobile/models/product.dart';
import 'package:stockfacil_mobile/screens/movement_history_screen.dart';
import 'package:stockfacil_mobile/services/inventory_repository.dart';

void main() {
  group('Issue #6 - Historial y filtrado de movimientos', () {
    test('ordena los movimientos del más reciente al más antiguo', () {
      final t1 = DateTime(2026, 11, 10, 10, 0);
      final t2 = DateTime(2026, 11, 12, 14, 30);
      final t3 = DateTime(2026, 11, 15, 9, 15);

      final repo = InventoryRepository(
        initialProducts: [],
        initialMovements: [
          InventoryMovement(
            id: 'm1',
            productId: 'p1',
            productName: 'Producto 1',
            type: MovementType.entrada,
            quantity: 10,
            previousStock: 0,
            newStock: 10,
            responsible: 'Admin',
            date: t1,
          ),
          InventoryMovement(
            id: 'm3',
            productId: 'p1',
            productName: 'Producto 1',
            type: MovementType.entrada,
            quantity: 5,
            previousStock: 8,
            newStock: 13,
            responsible: 'Admin',
            date: t3,
          ),
          InventoryMovement(
            id: 'm2',
            productId: 'p1',
            productName: 'Producto 1',
            type: MovementType.salida,
            quantity: 2,
            previousStock: 10,
            newStock: 8,
            responsible: 'Admin',
            date: t2,
          ),
        ],
      );

      final ordered = repo.getAllMovements();
      expect(ordered[0].id, 'm3'); // 15 de nov
      expect(ordered[1].id, 'm2'); // 12 de nov
      expect(ordered[2].id, 'm1'); // 10 de nov
    });

    test('conserva y permite consultar historial de producto desactivado', () {
      final repo = InventoryRepository(
        initialProducts: [
          const Product(
            id: 'p-inactivo',
            name: 'Producto Descontinuado',
            sku: 'PD-01',
            category: 'Cat',
            price: 20,
            stock: 0,
            minStock: 5,
            isActive: false, // desactivado
          ),
        ],
        initialMovements: [
          InventoryMovement(
            id: 'm-old',
            productId: 'p-inactivo',
            productName: 'Producto Descontinuado',
            type: MovementType.entrada,
            quantity: 10,
            previousStock: 0,
            newStock: 10,
            responsible: 'Operador Antiguo',
            date: DateTime(2026, 10, 1),
            observation: 'Entrada histórica',
          ),
        ],
      );

      final movements = repo.getAllMovements();
      expect(movements.length, 1);
      expect(movements.first.productName, 'Producto Descontinuado');
      expect(movements.first.observation, 'Entrada histórica');
    });

    testWidgets(
      'muestra datos completos, no ofrece editar/eliminar y permite filtrar y limpiar',
      (tester) async {
        final now = DateTime.now();
        final repo = InventoryRepository(
          initialProducts: [
            const Product(
              id: 'p1',
              name: 'Arroz blanco',
              sku: 'AB-01',
              category: 'Abarrotes',
              price: 10,
              stock: 20,
              minStock: 5,
            ),
            const Product(
              id: 'p2',
              name: 'Aceite vegetal',
              sku: 'AV-02',
              category: 'Abarrotes',
              price: 15,
              stock: 10,
              minStock: 5,
            ),
          ],
          initialMovements: [
            InventoryMovement(
              id: 'mov-1',
              productId: 'p1',
              productName: 'Arroz blanco',
              type: MovementType.entrada,
              quantity: 20,
              previousStock: 0,
              newStock: 20,
              responsible: 'Admin',
              date: now.subtract(const Duration(hours: 2)),
              observation: 'Compra inicial',
            ),
            InventoryMovement(
              id: 'mov-2',
              productId: 'p2',
              productName: 'Aceite vegetal',
              type: MovementType.salida,
              quantity: 5,
              previousStock: 15,
              newStock: 10,
              responsible: 'Cajero1',
              date: now.subtract(const Duration(hours: 1)),
              observation: 'Venta regular',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MovementHistoryScreen(repository: repo),
            ),
          ),
        );

        // Verificar datos completos
        expect(find.text('Arroz blanco'), findsOneWidget);
        expect(find.text('+20 un. (Entrada)'), findsOneWidget);
        expect(find.text('Saldo: 0 → 20 un.'), findsOneWidget);
        expect(find.text('Responsable: Admin'), findsOneWidget);
        expect(find.text('Observación: Compra inicial'), findsOneWidget);

        expect(find.text('Aceite vegetal'), findsOneWidget);
        expect(find.text('-5 un. (Salida)'), findsOneWidget);
        expect(find.text('Saldo: 15 → 10 un.'), findsOneWidget);

        // Verificar que es de sólo lectura (no hay botones de editar ni eliminar)
        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);

        // Filtrar por tipo: Entradas
        await tester.tap(find.byKey(const Key('history_filter_type')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Entradas').last);
        await tester.pumpAndSettle();

        // Debe mostrar solo Arroz blanco y no Aceite vegetal
        expect(find.text('Arroz blanco'), findsOneWidget);
        expect(find.text('Aceite vegetal'), findsNothing);

        // Limpiar filtros
        await tester.tap(find.byKey(const Key('clear_history_filters_button')));
        await tester.pumpAndSettle();

        // Ambos visibles de nuevo
        expect(find.text('Arroz blanco'), findsOneWidget);
        expect(find.text('Aceite vegetal'), findsOneWidget);
      },
    );

    testWidgets('distingue historial vacío', (tester) async {
      final repoVacio = InventoryRepository(
        initialProducts: [],
        initialMovements: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovementHistoryScreen(repository: repoVacio),
          ),
        ),
      );

      expect(
        find.text('No hay movimientos registrados en el historial'),
        findsOneWidget,
      );
    });
  });
}
