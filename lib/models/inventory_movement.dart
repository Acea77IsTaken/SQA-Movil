enum MovementType {
  entrada,
  salida;

  String get label {
    switch (this) {
      case MovementType.entrada:
        return 'Entrada';
      case MovementType.salida:
        return 'Salida';
    }
  }
}

class InventoryMovement {
  final String id;
  final String productId;
  final String productName;
  final MovementType type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String responsible;
  final DateTime date;
  final String? observation;

  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.responsible,
    required this.date,
    this.observation,
  });
}
