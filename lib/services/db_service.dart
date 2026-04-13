import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Inicializar la base de datos
  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Crear la base de datos y las tablas
  Future<Database> _initDatabase() async {
    try {
      // Obtener la ruta de la aplicación
      final String dbPath = await getDatabasesPath();
      final String path = join(dbPath, 'smartwallet.db');

      // Crear el directorio si no existe
      final dir = Directory(dbPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Abrir la base de datos
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (Database db, int version) async {
            await db.execute('''
              CREATE TABLE transacciones(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL,
                tipo TEXT NOT NULL,
                categoria TEXT NOT NULL,
                monto REAL NOT NULL,
                fecha INTEGER NOT NULL
              )
            ''');
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Insertar nueva transacción
  Future<int> insertTransaccion({
    required String nombre,
    required String tipo,
    required String categoria,
    required double monto,
    required DateTime fecha,
  }) async {
    final db = await _getDatabase();
    return await db.insert('transacciones', {
      'nombre': nombre,
      'tipo': tipo,
      'categoria': categoria,
      'monto': monto,
      'fecha': fecha.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Obtener todas las transacciones
  Future<List<Map<String, dynamic>>> getTransacciones() async {
    final db = await _getDatabase();
    final result = await db.query('transacciones', orderBy: 'fecha DESC');
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
    final db = await _getDatabase();
    final result = await db.query(
      'transacciones',
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'fecha DESC',
    );
    return result.map((map) => _mapToTransaccion(map)).toList();
  }

  // Calcular balance total
  Future<double> calcularBalance() async {
    final db = await _getDatabase();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) as total FROM transacciones',
    );
    return (result.first['total'] as num).toDouble();
  }

  // Calcular balance por tipo
  Future<double> calcularBalancePorTipo(String tipo) async {
    final db = await _getDatabase();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) as total FROM transacciones WHERE tipo = ?',
      [tipo],
    );
    return (result.first['total'] as num).toDouble();
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
    final db = await _getDatabase();
    return await db.update(
      'transacciones',
      {
        'nombre': nombre,
        'tipo': tipo,
        'categoria': categoria,
        'monto': monto,
        'fecha': fecha.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Eliminar transacción
  Future<int> deleteTransaccion(int id) async {
    final db = await _getDatabase();
    return await db.delete('transacciones', where: 'id = ?', whereArgs: [id]);
  }

  // Obtener todas las categorías únicas
  Future<List<String>> getCategoriasUnicas() async {
    final db = await _getDatabase();
    final result = await db.rawQuery(
      'SELECT DISTINCT categoria FROM transacciones ORDER BY categoria',
    );
    return result.map((row) => row['categoria'] as String).toList();
  }

  // Limpiar toda la base de datos
  Future<void> clearDatabase() async {
    final db = await _getDatabase();
    await db.delete('transacciones');
  }

  // Cerrar la base de datos
  Future<void> close() async {
    final db = await _getDatabase();
    await db.close();
    _database = null;
  }
}
