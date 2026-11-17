import '../models/inventory_movement.dart';
import '../models/product.dart';

class InventoryValidationException implements Exception {
  final String message;
  const InventoryValidationException(this.message);

  @override
  String toString() => message;
}

class DashboardSummary {
  final int totalProducts;
  final int totalUnits;
  final int lowStockCount;
  final int outOfStockCount;
  final List<Product> alerts;
  final List<InventoryMovement> recentMovements;

  const DashboardSummary({
    required this.totalProducts,
    required this.totalUnits,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.alerts,
    required this.recentMovements,
  });
}

class InventoryRepository {
  final List<Product> _products = [];
  final List<InventoryMovement> _movements = [];

  static const List<String> availableCategories = [
    'Abarrotes',
    'Bebidas',
    'Snacks',
    'Limpieza',
    'Higiene personal',
    'Lácteos',
    'Carnicería',
    'Panadería',
  ];

  InventoryRepository({
    List<Product>? initialProducts,
    List<InventoryMovement>? initialMovements,
  }) {
    if (initialProducts != null) {
      _products.addAll(initialProducts);
    } else {
      _seedDefaultProducts();
    }

    if (initialMovements != null) {
      _movements.addAll(initialMovements);
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

  List<Product> getAllProducts() {
    return List.unmodifiable(_products);
  }

  List<Product> getLowOrOutOfStockProducts() {
    return _products.where((p) => p.isActive && p.stock <= p.minStock).toList();
  }

  List<InventoryMovement> getAllMovements() {
    final sorted = List<InventoryMovement>.from(_movements);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  DashboardSummary getDashboardSummary() {
    final active = getAllActiveProducts();
    final totalUnits = active.fold<int>(0, (sum, p) => sum + p.stock);
    final lowStock = getLowOrOutOfStockProducts()
      ..sort((a, b) {
        final cmp = a.stock.compareTo(b.stock);
        return cmp != 0 ? cmp : a.name.compareTo(b.name);
      });
    final outOfStockCount = active.where((p) => p.stock == 0).length;
    final recent = getAllMovements().take(5).toList();

    return DashboardSummary(
      totalProducts: active.length,
      totalUnits: totalUnits,
      lowStockCount: lowStock.length,
      outOfStockCount: outOfStockCount,
      alerts: lowStock.take(4).toList(),
      recentMovements: recent,
    );
  }

  List<Product> searchProducts(String query) {
    return filterProducts(query: query, status: 'active');
  }

  List<Product> filterProducts({
    String query = '',
    String? category,
    String status = 'active',
  }) {
    final cleanQuery = query.trim().toLowerCase();
    return _products.where((p) {
      if (status == 'active' && !p.isActive) return false;
      if (status == 'inactive' && p.isActive) return false;
      if (category != null && category.isNotEmpty && p.category != category) {
        return false;
      }
      if (cleanQuery.isEmpty) return true;
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

  Product registerProduct({
    required String name,
    required String rawSku,
    required String category,
    required double price,
    required int initialStock,
    required int minStock,
    String? description,
    String responsible = 'Admin',
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const InventoryValidationException(
        'El nombre del producto no puede estar vacío',
      );
    }

    final normalizedSku = rawSku.trim().toUpperCase();
    if (normalizedSku.isEmpty) {
      throw const InventoryValidationException('El SKU es obligatorio');
    }

    if (findBySku(normalizedSku) != null) {
      throw InventoryValidationException(
        'El SKU "$normalizedSku" ya se encuentra registrado',
      );
    }

    if (!availableCategories.contains(category)) {
      throw InventoryValidationException(
        'La categoría "$category" no es válida',
      );
    }

    if (price < 0) {
      throw const InventoryValidationException(
        'El precio no puede ser negativo',
      );
    }

    final priceStr = price.toString();
    if (priceStr.contains('.')) {
      final decimals = priceStr.split('.')[1];
      if (decimals.length > 2) {
        throw const InventoryValidationException(
          'El precio solo puede tener hasta dos decimales',
        );
      }
    }

    if (initialStock < 0) {
      throw const InventoryValidationException(
        'El stock inicial no puede ser negativo',
      );
    }

    if (minStock < 0) {
      throw const InventoryValidationException(
        'El stock mínimo no puede ser negativo',
      );
    }

    final newId = (DateTime.now().millisecondsSinceEpoch).toString();
    final newProduct = Product(
      id: newId,
      name: cleanName,
      sku: normalizedSku,
      category: category,
      price: price,
      stock: initialStock,
      minStock: minStock,
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      isActive: true,
    );

    _products.add(newProduct);

    if (initialStock > 0) {
      final movement = InventoryMovement(
        id: 'mov-${DateTime.now().microsecondsSinceEpoch}',
        productId: newProduct.id,
        productName: newProduct.name,
        type: MovementType.entrada,
        quantity: initialStock,
        previousStock: 0,
        newStock: initialStock,
        responsible: responsible,
        date: DateTime.now(),
        observation: 'Inventario inicial',
      );
      _movements.add(movement);
    }

    return newProduct;
  }

  /// Edición de datos de un producto existente (como en ProductController::update de la web)
  Product editProduct({
    required String id,
    required String name,
    required String rawSku,
    required String category,
    required double price,
    required int minStock,
    String? description,
  }) {
    final existing = findById(id);
    if (existing == null) {
      throw const InventoryValidationException('Producto no encontrado');
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const InventoryValidationException(
        'El nombre del producto no puede estar vacío',
      );
    }

    final normalizedSku = rawSku.trim().toUpperCase();
    if (normalizedSku.isEmpty) {
      throw const InventoryValidationException('El SKU es obligatorio');
    }

    final duplicate = findBySku(normalizedSku);
    if (duplicate != null && duplicate.id != id) {
      throw InventoryValidationException(
        'El SKU "$normalizedSku" ya se encuentra registrado',
      );
    }

    if (!availableCategories.contains(category)) {
      throw InventoryValidationException(
        'La categoría "$category" no es válida',
      );
    }

    if (price < 0) {
      throw const InventoryValidationException(
        'El precio no puede ser negativo',
      );
    }

    if (minStock < 0) {
      throw const InventoryValidationException(
        'El stock mínimo no puede ser negativo',
      );
    }

    final updated = existing.copyWith(
      name: cleanName,
      sku: normalizedSku,
      category: category,
      price: price,
      minStock: minStock,
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
    );
    updateProduct(updated);
    return updated;
  }

  /// Desactivar un producto conservando su historial (como en ProductController::deactivate de la web)
  Product deactivateProduct(String id) {
    final existing = findById(id);
    if (existing == null) {
      throw const InventoryValidationException('Producto no encontrado');
    }
    final deactivated = existing.copyWith(isActive: false);
    updateProduct(deactivated);
    return deactivated;
  }

  InventoryMovement registerMovement({
    required String productId,
    required MovementType type,
    required int quantity,
    String? observation,
    String responsible = 'Admin',
  }) {
    final product = findById(productId);
    if (product == null) {
      throw const InventoryValidationException('Producto no encontrado');
    }

    if (!product.isActive) {
      throw const InventoryValidationException(
        'No se pueden realizar movimientos en productos inactivos',
      );
    }

    if (quantity <= 0) {
      throw const InventoryValidationException(
        'La cantidad debe ser un entero positivo mayor a cero',
      );
    }

    final currentStock = product.stock;
    final int newStock;

    if (type == MovementType.entrada) {
      newStock = currentStock + quantity;
    } else {
      if (quantity > currentStock) {
        throw InventoryValidationException(
          'Saldo insuficiente. El stock actual es $currentStock y se intentó retirar $quantity.',
        );
      }
      newStock = currentStock - quantity;
    }

    final updatedProduct = product.copyWith(stock: newStock);
    updateProduct(updatedProduct);

    final movement = InventoryMovement(
      id: 'mov-${DateTime.now().microsecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      type: type,
      quantity: quantity,
      previousStock: currentStock,
      newStock: newStock,
      responsible: responsible,
      date: DateTime.now(),
      observation: observation?.trim().isEmpty == true
          ? null
          : observation?.trim(),
    );
    _movements.add(movement);

    return movement;
  }

  static Product productFromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      category: (json['category'] ?? 'Abarrotes').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      minStock: (json['minimum_stock'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
      isActive: json['is_active'] == true,
    );
  }

  static InventoryMovement movementFromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? 'entrada').toString();
    final parsedDate =
        DateTime.tryParse((json['created_at'] ?? '').toString()) ??
        DateTime.now();
    return InventoryMovement(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      productName: (json['product_name'] ?? 'Producto').toString(),
      type: typeStr == 'salida' ? MovementType.salida : MovementType.entrada,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (json['previous_stock'] as num?)?.toInt() ?? 0,
      newStock: (json['resulting_stock'] as num?)?.toInt() ?? 0,
      responsible: (json['responsible'] ?? 'Administrador').toString(),
      date: parsedDate,
      observation: json['note']?.toString(),
    );
  }

  /// Aplica los datos recibidos desde el endpoint /api/sync del servidor web Laravel
  void applyRemoteSyncData(Map<String, dynamic> payload) {
    final rawProducts = payload['products'];
    if (rawProducts is List) {
      _products
        ..clear()
        ..addAll(
          rawProducts.whereType<Map<String, dynamic>>().map(productFromJson),
        );
    }

    final rawMovements = payload['movements'];
    if (rawMovements is List) {
      _movements
        ..clear()
        ..addAll(
          rawMovements.whereType<Map<String, dynamic>>().map(movementFromJson),
        );
    }
  }

  void upsertProduct(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
  }

  void recordSyncedMovement(InventoryMovement movement) {
    _movements.insert(0, movement);
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
    _movements.clear();
  }
}
