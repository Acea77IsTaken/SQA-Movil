import 'package:flutter/material.dart';
import '../models/inventory_movement.dart';
import '../services/inventory_repository.dart';

class MovementHistoryScreen extends StatefulWidget {
  final InventoryRepository repository;

  const MovementHistoryScreen({
    super.key,
    required this.repository,
  });

  @override
  State<MovementHistoryScreen> createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  String? _selectedProductId;
  MovementType? _selectedType;

  void _clearFilters() {
    setState(() {
      _selectedProductId = null;
      _selectedType = null;
    });
  }

  String _formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final allMovements = widget.repository.getAllMovements();
    final allProducts = widget.repository.getAllProducts();

    final filteredMovements = allMovements.where((m) {
      if (_selectedProductId != null && m.productId != _selectedProductId) {
        return false;
      }
      if (_selectedType != null && m.type != _selectedType) {
        return false;
      }
      return true;
    }).toList();

    final hasActiveFilter = _selectedProductId != null || _selectedType != null;

    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      key: const Key('history_filter_product'),
                      initialValue: _selectedProductId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Todos los productos',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...allProducts.map((p) {
                          return DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedProductId = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<MovementType?>(
                      key: const Key('history_filter_type'),
                      initialValue: _selectedType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de movimiento',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem<MovementType?>(
                          value: null,
                          child: Text(
                            'Todos los tipos',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem<MovementType?>(
                          value: MovementType.entrada,
                          child: Text('Entradas'),
                        ),
                        DropdownMenuItem<MovementType?>(
                          value: MovementType.salida,
                          child: Text('Salidas'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedType = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (hasActiveFilter) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('clear_history_filters_button'),
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Limpiar filtros'),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Lista
        Expanded(
          child: Builder(
            builder: (context) {
              if (allMovements.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay movimientos registrados en el historial',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (filteredMovements.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No se encontraron movimientos con los filtros seleccionados',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Mostrar todos los movimientos'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                key: const Key('movement_history_list_view'),
                padding: const EdgeInsets.all(16),
                itemCount: filteredMovements.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final mov = filteredMovements[index];
                  final isEntrada = mov.type == MovementType.entrada;
                  final badgeColor = isEntrada ? Colors.green.shade800 : Colors.red.shade800;
                  final badgeBg = isEntrada ? Colors.green.shade50 : Colors.red.shade50;
                  final sign = isEntrada ? '+' : '-';

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
                                  mov.productName,
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
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: badgeColor),
                                ),
                                child: Text(
                                  '$sign${mov.quantity} un. (${mov.type.label})',
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saldo: ${mov.previousStock} → ${mov.newStock} un.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDate(mov.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Responsable: ${mov.responsible}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (mov.observation != null && mov.observation!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                'Observación: ${mov.observation}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
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
