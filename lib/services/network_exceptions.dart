enum NetworkErrorType {
  noConnection,
  timeout,
  serverError,
  uncertainWrite,
}

class NetworkException implements Exception {
  final NetworkErrorType type;
  final String message;

  const NetworkException({
    required this.type,
    required this.message,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      type: NetworkErrorType.noConnection,
      message: 'Sin conexión a la red. Verifica tu conexión e inténtalo de nuevo.',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      type: NetworkErrorType.timeout,
      message: 'Tiempo de espera agotado al conectar con el servidor.',
    );
  }

  factory NetworkException.serverError([int? statusCode]) {
    final detail = statusCode != null ? ' (Código $statusCode)' : '';
    return NetworkException(
      type: NetworkErrorType.serverError,
      message: 'Error en el servidor$detail. Inténtalo más tarde.',
    );
  }

  factory NetworkException.uncertainWrite() {
    return const NetworkException(
      type: NetworkErrorType.uncertainWrite,
      message:
          'No se pudo confirmar si la operación fue guardada. Verifica el inventario antes de repetir el envío.',
    );
  }

  @override
  String toString() => message;
}
