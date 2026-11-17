import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/inventory_repository.dart';

class RegisterProductScreen extends StatefulWidget {
  final InventoryRepository repository;
  final Product? existingProduct;

  const RegisterProductScreen({
    super.key,
    required this.repository,
    this.existingProduct,
  });

  @override
  State<RegisterProductScreen> createState() => _RegisterProductScreenState();
}

class _RegisterProductScreenState extends State<RegisterProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _initialStockController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late String _selectedCategory;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditMode => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProduct;
    if (existing != null) {
      _nameController.text = existing.name;
      _skuController.text = existing.sku;
      _priceController.text = existing.price.toStringAsFixed(2);
      _minStockController.text = existing.minStock.toString();
      _descriptionController.text = existing.description ?? '';
      _selectedCategory =
          InventoryRepository.availableCategories.contains(existing.category)
          ? existing.category
          : InventoryRepository.availableCategories.first;
    } else {
      _selectedCategory = InventoryRepository.availableCategories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _initialStockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() {
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(
        () => _errorMessage = 'El nombre del producto no puede estar vacío',
      );
      return;
    }

    final rawSku = _skuController.text;
    if (rawSku.trim().isEmpty) {
      setState(() => _errorMessage = 'El SKU es obligatorio');
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price < 0) {
      setState(() => _errorMessage = 'Ingresa un precio válido no negativo');
      return;
    }

    int initialStock = 0;
    if (!_isEditMode) {
      final parsedInitial = int.tryParse(_initialStockController.text.trim());
      if (parsedInitial == null || parsedInitial < 0) {
        setState(
          () => _errorMessage =
              'El stock inicial debe ser un entero no negativo',
        );
        return;
      }
      initialStock = parsedInitial;
    }

    final minStock = int.tryParse(_minStockController.text.trim());
    if (minStock == null || minStock < 0) {
      setState(
        () => _errorMessage = 'El stock mínimo debe ser un entero no negativo',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Product product;
      if (_isEditMode) {
        product = widget.repository.editProduct(
          id: widget.existingProduct!.id,
          name: name,
          rawSku: rawSku,
          category: _selectedCategory,
          price: price,
          minStock: minStock,
          description: _descriptionController.text,
        );
      } else {
        product = widget.repository.registerProduct(
          name: name,
          rawSku: rawSku,
          category: _selectedCategory,
          price: price,
          initialStock: initialStock,
          minStock: minStock,
          description: _descriptionController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop<Product>(product);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar producto' : 'Registrar producto'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    key: const Key('register_error_banner'),
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
                TextField(
                  key: const Key('product_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto *',
                    hintText: 'Ej. Harina de trigo 1kg',
                  ),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('product_sku_field'),
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU / Código *',
                    hintText: 'Ej. HT-005',
                  ),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('product_category_field'),
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría *'),
                  items: InventoryRepository.availableCategories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('product_price_field'),
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio (Bs.) *',
                    hintText: 'Ej. 12.50',
                    prefixText: 'Bs. ',
                  ),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!_isEditMode) ...[
                      Expanded(
                        child: TextField(
                          key: const Key('product_initial_stock_field'),
                          controller: _initialStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock inicial *',
                            hintText: 'Ej. 20',
                          ),
                          enabled: !_isSubmitting,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: TextField(
                        key: const Key('product_min_stock_field'),
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock mínimo *',
                          hintText: 'Ej. 5',
                        ),
                        enabled: !_isSubmitting,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('product_description_field'),
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('register_product_submit_button'),
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
                      : Text(
                          _isEditMode
                              ? 'Actualizar producto'
                              : 'Guardar producto',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
