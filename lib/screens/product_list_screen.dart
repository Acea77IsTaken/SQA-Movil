import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/inventory_repository.dart';
import 'register_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  final InventoryRepository repository;

  const ProductListScreen({
    super.key,
    required this.repository,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> _navigateToRegister() async {
    final result = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => RegisterProductScreen(repository: widget.repository),
      ),
    );
    if (result != null) {
      setState(() {});
    }
  }

  Color _getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.agotado:
        return Colors.red.shade700;
      case StockStatus.stockBajo:
        return Colors.amber.shade800;
      case StockStatus.disponible:
        return Colors.green.shade700;
    }
  }

  Color _getStatusBgColor(StockStatus status) {
    switch (status) {
      case StockStatus.agotado:
        return Colors.red.shade50;
      case StockStatus.stockBajo:
        return Colors.amber.shade50;
      case StockStatus.disponible:
        return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = widget.repository.getAllActiveProducts();
    final filteredProducts = widget.repository.searchProducts(_searchQuery);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('product_search_field'),
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o SKU...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            key: const Key('clear_search_button'),
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('open_register_product_button'),
                icon: const Icon(Icons.add),
                tooltip: 'Registrar producto',
                onPressed: _navigateToRegister,
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (allProducts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'El catálogo de productos está vacío',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (filteredProducts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No se encontraron productos para la búsqueda',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          key: const Key('clear_search_link'),
                          onPressed: _clearSearch,
                          child: const Text('Limpiar búsqueda'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                key: const Key('product_list_view'),
                padding: const EdgeInsets.all(16),
                itemCount: filteredProducts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final status = product.status;
                  final statusColor = _getStatusColor(status);
                  final statusBg = _getStatusBgColor(status);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
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
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  status.label,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'SKU: ${product.sku}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.category,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.formattedPrice,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff234e43),
                                ),
                              ),
                              Text(
                                'Stock: ${product.stock} un.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
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
            },
          ),
        ),
      ],
    );
  }
}
