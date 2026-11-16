import 'package:flutter/material.dart';
import '../services/network_exceptions.dart';

class ConnectionErrorBanner extends StatelessWidget {
  final NetworkException exception;
  final VoidCallback onRetry;
  final bool isRetrying;

  const ConnectionErrorBanner({
    super.key,
    required this.exception,
    required this.onRetry,
    this.isRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUncertain = exception.type == NetworkErrorType.uncertainWrite;
    final bgColor = isUncertain ? Colors.orange.shade50 : Colors.red.shade50;
    final borderColor = isUncertain ? Colors.orange.shade300 : Colors.red.shade300;
    final textColor = isUncertain ? Colors.orange.shade900 : Colors.red.shade900;
    final iconData = isUncertain ? Icons.warning_amber_rounded : Icons.wifi_off_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exception.message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: isRetrying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : OutlinedButton.icon(
                    key: const Key('connection_retry_button'),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reintentar'),
                  ),
          ),
        ],
      ),
    );
  }
}
