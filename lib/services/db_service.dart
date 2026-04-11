class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static int _nextId = 1;
  static final List<Map<String, dynamic>> _transacciones = [];

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Insertar nueva transacción
  Future<int> insertTransaccion({
    required String nombre,
    required String tipo,
    required String categoria,
    required double monto,
    required DateTime fecha,
  }) async {
    final id = _nextId++;
    _transacciones.add({
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'categoria': categoria,
      'monto': monto,
      'fecha': fecha.millisecondsSinceEpoch,
    });
    return id;
  }

  // Obtener todas las transacciones
  Future<List<Map<String, dynamic>>> getTransacciones() async {
    final result = List<Map<String, dynamic>>.from(_transacciones);
    result.sort((a, b) => (b['fecha'] as int).compareTo(a['fecha'] as int));
    return result;
  }

  // Convertir resultado a mapa de transacción con formato
  Map<String, dynamic> _mapToTransaccion(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'titulo': map['nombre'],
      'nombre': map['nombre'],
      'monto': map['monto'] as double,
      'tipo': map['tipo'],
      'categoria': map['categoria'],
      'fecha': DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int),
    };
  }

  // Obtener transacciones con formato para mostrar
  Future<List<Map<String, dynamic>>> getTransaccionesFormateadas() async {
    final result = await getTransacciones();
    return result.map((map) => _mapToTransaccion(map)).toList();
  }

  // Obtener transacciones filtradas por tipo
  Future<List<Map<String, dynamic>>> getTransaccionesByTipo(String tipo) async {
    final result = await getTransacciones();
    return result
        .where((tx) => tx['tipo'] == tipo)
        .map((map) => _mapToTransaccion(map))
        .toList();
  }

  // Calcular balance total
  Future<double> calcularBalance() async {
    double total = 0;
    for (final tx in _transacciones) {
      total += (tx['monto'] as double);
    }
    return total;
  }

  // Calcular balance por tipo
  Future<double> calcularBalancePorTipo(String tipo) async {
    double total = 0;
    for (final tx in _transacciones) {
      if (tx['tipo'] == tipo) {
        total += (tx['monto'] as double);
      }
    }
    return total;
  }

  // Actualizar transacción
  Future<int> updateTransaccion(
    int id, {
    required String nombre,
    required String tipo,
    required String categoria,
    required double monto,
    required DateTime fecha,
  }) async {
    final index = _transacciones.indexWhere((tx) => tx['id'] == id);
    if (index != -1) {
      _transacciones[index] = {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'categoria': categoria,
        'monto': monto,
        'fecha': fecha.millisecondsSinceEpoch,
      };
      return 1;
    }
    return 0;
  }

  // Eliminar transacción
  Future<int> deleteTransaccion(int id) async {
    final index = _transacciones.indexWhere((tx) => tx['id'] == id);
    if (index != -1) {
      _transacciones.removeAt(index);
      return 1;
    }
    return 0;
  }

  // Obtener todas las categorías únicas
  Future<List<String>> getCategoriasUnicas() async {
    final categorias = <String>{};
    for (final tx in _transacciones) {
      categorias.add(tx['categoria'] as String);
    }
    return categorias.toList();
  }

  // Limpiar toda la base de datos
  Future<void> clearDatabase() async {
    _transacciones.clear();
    _nextId = 1;
  }

  // Cerrar la base de datos
  Future<void> close() async {
    // No-op para compatibilidad
  }
}
