enum StockStatus {
  agotado,
  stockBajo,
  disponible;

  String get label {
    switch (this) {
      case StockStatus.agotado:
        return 'Agotado';
      case StockStatus.stockBajo:
        return 'Stock bajo';
      case StockStatus.disponible:
        return 'Disponible';
    }
  }
}

class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double price;
  final int stock;
  final int minStock;
  final String? description;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.stock,
    required this.minStock,
    this.description,
    this.isActive = true,
  });

  StockStatus get status {
    if (stock <= 0) {
      return StockStatus.agotado;
    }
    if (stock <= minStock) {
      return StockStatus.stockBajo;
    }
    return StockStatus.disponible;
  }

  String get formattedPrice => 'Bs. ${price.toStringAsFixed(2)}';

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    double? price,
    int? stock,
    int? minStock,
    String? description,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
