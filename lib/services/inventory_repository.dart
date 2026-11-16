import '../models/inventory_movement.dart';
import '../models/product.dart';

class InventoryValidationException implements Exception {
  final String message;
  const InventoryValidationException(this.message);

  @override
  String toString() => message;
}

class InventoryRepository {
  final List<Product> _products = [];
  final List<InventoryMovement> _movements = [];

  static const List<String> availableCategories = [
    'Abarrotes',
    'Lácteos',
    'Bebidas',
    'Limpieza',
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
    // Ordenar del más reciente al más antiguo
    final sorted = List<InventoryMovement>.from(_movements);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
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

  /// Registro atómico de productos con validaciones y trazabilidad de stock inicial
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
      throw const InventoryValidationException('El nombre del producto no puede estar vacío');
    }

    final normalizedSku = rawSku.trim().toUpperCase();
    if (normalizedSku.isEmpty) {
      throw const InventoryValidationException('El SKU es obligatorio');
    }

    if (findBySku(normalizedSku) != null) {
      throw InventoryValidationException('El SKU "$normalizedSku" ya se encuentra registrado');
    }

    if (!availableCategories.contains(category)) {
      throw InventoryValidationException('La categoría "$category" no es válida');
    }

    if (price < 0) {
      throw const InventoryValidationException('El precio no puede ser negativo');
    }

    // Comprobar máximo dos decimales
    final priceStr = price.toString();
    if (priceStr.contains('.')) {
      final decimals = priceStr.split('.')[1];
      if (decimals.length > 2) {
        throw const InventoryValidationException('El precio solo puede tener hasta dos decimales');
      }
    }

    if (initialStock < 0) {
      throw const InventoryValidationException('El stock inicial no puede ser negativo');
    }

    if (minStock < 0) {
      throw const InventoryValidationException('El stock mínimo no puede ser negativo');
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
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      isActive: true,
    );

    // Operación atómica: agregar producto y si stock inicial > 0, crear movimiento de entrada inicial
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

  /// Registro atómico de movimientos de entrada y salida
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
      throw const InventoryValidationException('No se pueden realizar movimientos en productos inactivos');
    }

    if (quantity <= 0) {
      throw const InventoryValidationException('La cantidad debe ser un entero positivo mayor a cero');
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

    // Actualizar producto
    final updatedProduct = product.copyWith(stock: newStock);
    updateProduct(updatedProduct);

    // Registrar movimiento
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
      observation: observation?.trim().isEmpty == true ? null : observation?.trim(),
    );
    _movements.add(movement);

    return movement;
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
