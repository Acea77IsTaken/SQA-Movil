import 'package:flutter/material.dart';
import 'screens/low_stock_screen.dart';
import 'screens/product_list_screen.dart';
import 'services/inventory_repository.dart';

class StockFacilApp extends StatelessWidget {
  final InventoryRepository? repository;

  const StockFacilApp({super.key, this.repository});

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
      home: InventoryHome(repository: repository),
    );
  }
}

class InventoryHome extends StatefulWidget {
  final InventoryRepository? repository;

  const InventoryHome({super.key, this.repository});

  @override
  State<InventoryHome> createState() => _InventoryHomeState();
}

class _InventoryHomeState extends State<InventoryHome> {
  late final InventoryRepository repository;
  int _selected = 0;
  static const _titles = ['Productos', 'Stock bajo', 'Historial'];

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? InventoryRepository();
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
                  : const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16),
                          Text('Tu inventario en este dispositivo.'),
                          SizedBox(height: 8),
                          Text(
                            'La base Flutter está lista. Las funciones del inventario se incorporan en sus respectivas ramas.',
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StockFácil')),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (value) => setState(() => _selected = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            label: 'Stock bajo',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}
