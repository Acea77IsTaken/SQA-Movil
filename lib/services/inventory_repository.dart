import '../models/product.dart';

class InventoryRepository {
  final List<Product> _products = [];

  InventoryRepository({List<Product>? initialProducts}) {
    if (initialProducts != null) {
      _products.addAll(initialProducts);
    } else {
      _seedDefaultProducts();
    }
  }

  void _seedDefaultProducts() {
    _products.addAll([
      const Product(
        id: '1',
        name: 'Arroz blanco 1kg',
        sku: 'AB-001',
        category: 'Abarrotes',
        price: 8.50,
        stock: 25,
        minStock: 10,
        description: 'Arroz de grano largo seleccionado.',
      ),
      const Product(
        id: '2',
        name: 'Aceite vegetal 900ml',
        sku: 'AV-002',
        category: 'Abarrotes',
        price: 13.00,
        stock: 5,
        minStock: 8,
        description: 'Aceite vegetal 100% puro.',
      ),
      const Product(
        id: '3',
        name: 'Azúcar refinada 1kg',
        sku: 'AR-003',
        category: 'Abarrotes',
        price: 6.00,
        stock: 0,
        minStock: 5,
        description: 'Azúcar blanca extrafina.',
      ),
      const Product(
        id: '4',
        name: 'Leche entera 1L',
        sku: 'LE-004',
        category: 'Lácteos',
        price: 7.50,
        stock: 12,
        minStock: 12,
        description: 'Leche fluida pasteurizada.',
      ),
    ]);
  }

  List<Product> getAllActiveProducts() {
    return _products.where((p) => p.isActive).toList();
  }

  List<Product> searchProducts(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return getAllActiveProducts();
    }
    return _products.where((p) {
      if (!p.isActive) return false;
      final nameMatches = p.name.toLowerCase().contains(cleanQuery);
      final skuMatches = p.sku.toLowerCase().contains(cleanQuery);
      return nameMatches || skuMatches;
    }).toList();
  }

  Product? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? findBySku(String sku) {
    final normalized = sku.trim().toUpperCase();
    try {
      return _products.firstWhere((p) => p.sku.toUpperCase() == normalized);
    } catch (_) {
      return null;
    }
  }

  void addProduct(Product product) {
    _products.add(product);
  }

  void updateProduct(Product updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
    }
  }

  void clearAll() {
    _products.clear();
  }
}
