import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/inventory_repository.dart';
import '../services/web_api_service.dart';
import 'register_movement_screen.dart';

class LowStockScreen extends StatefulWidget {
  final InventoryRepository repository;
  final WebApiService? apiService;

  const LowStockScreen({
    super.key,
    required this.repository,
    this.apiService,
  });

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  Future<void> _navigateToRestock(Product product) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterMovementScreen(
          repository: widget.repository,
          initialProductId: product.id,
          apiService: widget.apiService,
        ),
      ),
    );
    if (result != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStockProducts = widget.repository.getLowOrOutOfStockProducts();

    if (lowStockProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Color(0xff234e43),
              ),
              SizedBox(height: 16),
              Text(
                'No hay productos con stock bajo o agotado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Todos los productos activos cuentan con existencias suficientes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('low_stock_list_view'),
      padding: const EdgeInsets.all(16),
      itemCount: lowStockProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = lowStockProducts[index];
        final isAgotado = product.stock == 0;
        final badgeColor = isAgotado ? Colors.red.shade700 : Colors.amber.shade800;
        final badgeBg = isAgotado ? Colors.red.shade50 : Colors.amber.shade50;
        final statusText = isAgotado ? 'Agotado' : 'Stock bajo';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isAgotado ? Colors.red.shade200 : Colors.amber.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${product.sku}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disponible: ${product.stock} un.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isAgotado ? Colors.red.shade800 : Colors.black87,
                          ),
                        ),
                        Text(
                          'Mínimo requerido: ${product.minStock} un.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      key: Key('restock_button_${product.id}'),
                      onPressed: () => _navigateToRestock(product),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Reponer'),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
