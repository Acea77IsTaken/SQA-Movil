import 'package:flutter/material.dart';
import '../models/inventory_movement.dart';
import '../services/inventory_repository.dart';
import '../services/network_exceptions.dart';
import '../services/web_api_service.dart';
import '../widgets/connection_error_banner.dart';

class DashboardScreen extends StatefulWidget {
  final InventoryRepository repository;
  final WebApiService? apiService;

  const DashboardScreen({
    super.key,
    required this.repository,
    this.apiService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WebApiService _apiService;
  NetworkException? _syncError;
  bool _isSyncing = false;
  String? _syncSuccessMessage;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? WebApiService();
  }

  Future<void> _handleWebSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _syncError = null;
      _syncSuccessMessage = null;
    });

    try {
      await _apiService.syncWithRepository(widget.repository);
      if (!mounted) return;
      setState(() {
        _syncSuccessMessage = 'Inventario sincronizado con el servidor web.';
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _syncError = e;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _syncError = NetworkException.noConnection();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.repository.getDashboardSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Principal - StockFácil'),
        actions: [
          IconButton(
            key: const Key('sync_web_button'),
            tooltip: 'Sincronizar con servidor Web',
            onPressed: _isSyncing ? null : _handleWebSync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_syncError != null)
                ConnectionErrorBanner(
                  exception: _syncError!,
                  onRetry: _handleWebSync,
                  isRetrying: _isSyncing,
                ),
              if (_syncSuccessMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    _syncSuccessMessage!,
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
              Row(
                children: [
                  _buildKpiCard(
                    'Productos activos',
                    '${summary.totalProducts}',
                    const Color(0xff234e43),
                  ),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                    'Unidades totales',
                    '${summary.totalUnits}',
                    Colors.blue.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildKpiCard(
                    'Stock bajo',
                    '${summary.lowStockCount}',
                    Colors.amber.shade800,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                    'Agotados',
                    '${summary.outOfStockCount}',
                    Colors.red.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Alertas recientes de stock',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (summary.alerts.isEmpty)
                const Text('Sin alertas de reposición pendientes.')
              else
                ...summary.alerts.map((p) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: p.stock == 0 ? Colors.red : Colors.amber.shade800,
                    ),
                    title: Text(p.name),
                    subtitle: Text('SKU: ${p.sku} • ${p.category}'),
                    trailing: Text(
                      '${p.stock} / mín. ${p.minStock}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              Text(
                'Últimos movimientos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (summary.recentMovements.isEmpty)
                const Text('Aún no se han registrado movimientos.')
              else
                ...summary.recentMovements.map((m) {
                  final isEntrada = m.type == MovementType.entrada;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isEntrada ? Icons.south_west : Icons.north_east,
                      color: isEntrada ? Colors.green : Colors.red,
                    ),
                    title: Text(m.productName),
                    subtitle: Text('Responsable: ${m.responsible}'),
                    trailing: Text(
                      '${isEntrada ? '+' : '-'}${m.quantity} (${m.previousStock}→${m.newStock})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEntrada
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
