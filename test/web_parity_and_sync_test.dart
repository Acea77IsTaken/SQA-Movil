import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfacil_mobile/app.dart';
import 'package:stockfacil_mobile/models/inventory_movement.dart';
import 'package:stockfacil_mobile/screens/dashboard_screen.dart';
import 'package:stockfacil_mobile/services/auth_service.dart';
import 'package:stockfacil_mobile/services/inventory_repository.dart';

void main() {
  group('Issue #10 - Paridad con Web y sincronización API', () {
    test('permite editar y desactivar productos conservando su historial', () {
      final repo = InventoryRepository(
        initialProducts: [],
        initialMovements: [],
      );

      final created = repo.registerProduct(
        name: 'Agua mineral 600 ml',
        rawSku: ' beb-001 ',
        category: 'Bebidas',
        price: 3.50,
        initialStock: 20,
        minStock: 5,
      );

      final edited = repo.editProduct(
        id: created.id,
        name: 'Agua mineral sin gas 600 ml',
        rawSku: 'BEB-001',
        category: 'Bebidas',
        price: 4.00,
        minStock: 8,
        description: 'Actualizado',
      );
      expect(edited.name, 'Agua mineral sin gas 600 ml');
      expect(edited.price, 4.00);
      expect(edited.minStock, 8);

      // Desactivar producto
      final deactivated = repo.deactivateProduct(created.id);
      expect(deactivated.isActive, isFalse);

      // Filtrado por estado como en la web
      expect(repo.filterProducts(status: 'active'), isEmpty);
      expect(repo.filterProducts(status: 'inactive').length, 1);
      expect(repo.filterProducts(status: 'all').length, 1);

      // El historial inicial se conserva
      expect(repo.getAllMovements().length, 1);
    });

    test('sincroniza datos recibidos desde /api/sync del backend web Laravel', () {
      final repo = InventoryRepository(
        initialProducts: [],
        initialMovements: [],
      );

      repo.applyRemoteSyncData({
        'products': [
          {
            'id': '101',
            'name': 'Detergente 1 kg',
            'sku': 'LIM-001',
            'category': 'Limpieza',
            'price': 18.0,
            'stock': 15,
            'minimum_stock': 4,
            'description': 'Sincronizado desde Laravel',
            'is_active': true,
          },
          {
            'id': '102',
            'name': 'Chocolate con leche',
            'sku': 'SNK-003',
            'category': 'Snacks',
            'price': 4.0,
            'stock': 0,
            'minimum_stock': 5,
            'is_active': true,
          },
        ],
        'movements': [
          {
            'id': '501',
            'product_id': '101',
            'product_name': 'Detergente 1 kg',
            'type': 'entrada',
            'quantity': 15,
            'previous_stock': 0,
            'resulting_stock': 15,
            'responsible': 'Administrador',
            'note': 'Stock inicial',
            'created_at': '2026-11-16T12:00:00Z',
          },
        ],
      });

      final summary = repo.getDashboardSummary();
      expect(summary.totalProducts, 2);
      expect(summary.totalUnits, 15);
      expect(summary.lowStockCount, 1);
      expect(summary.outOfStockCount, 1);
      expect(summary.recentMovements.first.type, MovementType.entrada);
    });

    test('autentica credenciales del seeder web y registra nuevos usuarios', () async {
      final auth = AuthService();

      final okWeb = await auth.login(
        rawEmail: '  ADMIN@stockfacil.test ',
        rawPassword: AuthService.webAdminPassword,
      );
      expect(okWeb, isTrue);
      expect(auth.isLoggedIn, isTrue);

      auth.logout();
      expect(auth.isLoggedIn, isFalse);

      final okReg = await auth.register(
        name: 'Operador Almacén',
        rawEmail: 'operador@stockfacil.test',
        rawPassword: 'Operador2026!',
        passwordConfirmation: 'Operador2026!',
      );
      expect(okReg, isTrue);
      expect(auth.currentUserName, 'Operador Almacén');
    });

    testWidgets('DashboardScreen muestra indicadores KPIs, alertas y movimientos', (
      tester,
    ) async {
      final repo = InventoryRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(repository: repo),
        ),
      );

      expect(find.text('Panel Principal - StockFácil'), findsOneWidget);
      expect(find.text('Productos activos'), findsOneWidget);
      expect(find.text('Unidades totales'), findsOneWidget);
      expect(find.text('Alertas recientes de stock'), findsOneWidget);
      expect(find.text('Últimos movimientos'), findsOneWidget);
    });

    testWidgets(
      'StockFacilApp inicia en LoginScreen, entra al inventario y vuelve al cerrar sesión',
      (tester) async {
        await tester.pumpWidget(const StockFacilApp());

        expect(find.text('Iniciar sesión - StockFácil'), findsOneWidget);
        expect(find.text('Productos'), findsNothing);

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'admin@stockfacil.test',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          AuthService.webAdminPassword,
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('StockFácil'), findsOneWidget);
        expect(find.text('Productos'), findsNWidgets(2));

        await tester.tap(find.byKey(const Key('open_auth_button')));
        await tester.pumpAndSettle();

        expect(find.text('Iniciar sesión - StockFácil'), findsOneWidget);
      },
    );
  });
}
