import 'package:flutter/material.dart';
import '../models/inventory_movement.dart';
import '../models/product.dart';
import '../services/inventory_repository.dart';
import '../services/web_api_service.dart';

class RegisterMovementScreen extends StatefulWidget {
  final InventoryRepository repository;
  final String? initialProductId;
  final WebApiService? apiService;

  const RegisterMovementScreen({
    super.key,
    required this.repository,
    this.initialProductId,
    this.apiService,
  });

  @override
  State<RegisterMovementScreen> createState() => _RegisterMovementScreenState();
}

class _RegisterMovementScreenState extends State<RegisterMovementScreen> {
  Product? _selectedProduct;
  MovementType _type = MovementType.entrada;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final activeProducts = widget.repository.getAllActiveProducts();
    if (widget.initialProductId != null) {
      _selectedProduct = widget.repository.findById(widget.initialProductId!);
    }
    _selectedProduct ??= activeProducts.isNotEmpty ? activeProducts.first : null;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (_selectedProduct == null) {
      setState(() => _errorMessage = 'Selecciona un producto');
      return;
    }

    final qtyText = _quantityController.text.trim();
    final qty = int.tryParse(qtyText);
    if (qty == null || qty <= 0) {
      setState(() => _errorMessage = 'La cantidad debe ser un número entero mayor a cero');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final InventoryMovement movement;
      final api = widget.apiService;
      if (api != null && api.isAuthenticated) {
        final result = await api.createMovement(
          productId: _selectedProduct!.id,
          type: _type,
          quantity: qty,
          observation: _observationController.text,
        );
        widget.repository.upsertProduct(result.product);
        widget.repository.recordSyncedMovement(result.movement);
        movement = result.movement;
      } else {
        movement = widget.repository.registerMovement(
          productId: _selectedProduct!.id,
          type: _type,
          quantity: qty,
          observation: _observationController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop<InventoryMovement>(movement);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProducts = widget.repository.getAllActiveProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar movimiento'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  key: const Key('movement_error_banner'),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              DropdownButtonFormField<Product>(
                key: const Key('movement_product_dropdown'),
                initialValue: _selectedProduct,
                decoration: const InputDecoration(
                  labelText: 'Producto *',
                ),
                items: activeProducts.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text('${p.name} (Stock: ${p.stock})'),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        setState(() {
                          _selectedProduct = val;
                        });
                      },
              ),
              const SizedBox(height: 16),
              SegmentedButton<MovementType>(
                key: const Key('movement_type_selector'),
                segments: const [
                  ButtonSegment(
                    value: MovementType.entrada,
                    label: Text('Entrada'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: MovementType.salida,
                    label: Text('Salida'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _isSubmitting
                    ? null
                    : (newSet) {
                        setState(() {
                          _type = newSet.first;
                        });
                      },
              ),
              const SizedBox(height: 16),
              if (_selectedProduct != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stock actual disponible:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${_selectedProduct!.stock} unidades',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff234e43),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('movement_quantity_field'),
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad *',
                  hintText: 'Ej. 5',
                ),
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('movement_observation_field'),
                controller: _observationController,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                  hintText: 'Ej. Compra a proveedor / Venta al mostrador',
                ),
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('movement_submit_button'),
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar movimiento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
