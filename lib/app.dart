import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/low_stock_screen.dart';
import 'screens/movement_history_screen.dart';
import 'screens/product_list_screen.dart';
import 'services/auth_service.dart';
import 'services/inventory_repository.dart';

class StockFacilApp extends StatelessWidget {
  final InventoryRepository? repository;
  final AuthService? authService;

  const StockFacilApp({
    super.key,
    this.repository,
    this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockFácil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff234e43)),
        scaffoldBackgroundColor: const Color(0xfff5f6f1),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: InventoryHome(
        repository: repository,
        authService: authService,
      ),
    );
  }
}

class InventoryHome extends StatefulWidget {
  final InventoryRepository? repository;
  final AuthService? authService;

  const InventoryHome({
    super.key,
    this.repository,
    this.authService,
  });

  @override
  State<InventoryHome> createState() => InventoryHomeState();
}

class InventoryHomeState extends State<InventoryHome> {
  late final InventoryRepository repository;
  late final AuthService authService;
  int _selected = 0;
  bool _isLoading = false;
  Timer? _pendingLoadTimer;
  static const _titles = ['Productos', 'Stock bajo', 'Historial'];

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? InventoryRepository();
    authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _pendingLoadTimer?.cancel();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index == _selected || index < 0 || index >= _titles.length) return;
    setState(() {
      _selected = index;
    });
  }

  void simulateAsyncLoad() {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _pendingLoadTimer?.cancel();
    _pendingLoadTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  Future<void> _openDashboard() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(repository: repository),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAuth() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => LoginScreen(
          authService: authService,
          onLoginSuccess: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            _titles[_selected],
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: _selected == 0
              ? ProductListScreen(repository: repository)
              : _selected == 1
                  ? LowStockScreen(repository: repository)
                  : MovementHistoryScreen(repository: repository),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selected == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selected != 0) {
          if (mounted) {
            setState(() {
              _selected = 0;
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('StockFácil'),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              key: const Key('open_dashboard_button'),
              tooltip: 'Panel Principal (Dashboard)',
              icon: const Icon(Icons.dashboard_outlined),
              onPressed: _openDashboard,
            ),
            IconButton(
              key: const Key('open_auth_button'),
              tooltip: authService.isLoggedIn
                  ? 'Cuenta (${authService.currentUserName})'
                  : 'Iniciar sesión / Registro',
              icon: Icon(
                authService.isLoggedIn
                    ? Icons.verified_user_outlined
                    : Icons.person_outline,
              ),
              onPressed: _openAuth,
            ),
          ],
        ),
        body: SafeArea(
          child: KeyedSubtree(
            key: ValueKey<int>(_selected),
            child: _buildBody(),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selected,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Productos',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              label: 'Stock bajo',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: 'Historial',
            ),
          ],
        ),
      ),
    );
  }
}
