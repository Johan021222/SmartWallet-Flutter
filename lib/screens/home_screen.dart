import 'package:flutter/material.dart';
import 'add_transaction.dart';
import '../services/db_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Servicio de base de datos e inicialización
  final DatabaseService _dbService = DatabaseService();
  String _filtroSeleccionado = 'Todas'; // Controla el filtro actual

  // 2. Actualizar UI cuando hay cambios
  void _actualizarUI() {
    setState(() {});
  }

  // 3. Método auxiliar: Formatea una fecha a formato DD/MM/YYYY
  String _formatoFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  // 3.1 Filtrar transacciones en memoria
  List<Map<String, dynamic>> _transaccionesFiltradas(
    List<Map<String, dynamic>> transacciones,
  ) {
    List<Map<String, dynamic>> resultado = List.from(transacciones);

    // Aplicar filtro según la selección
    switch (_filtroSeleccionado) {
      case 'Ingresos':
        resultado = resultado.where((tx) => tx['tipo'] == 'Ingreso').toList();
        break;
      case 'Egresos':
        resultado = resultado.where((tx) => tx['tipo'] == 'Egreso').toList();
        break;
      case 'Más Recientes':
        resultado.sort(
          (a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime),
        );
        break;
      case 'Todas':
      default:
        // Sin filtro adicional
        break;
    }

    return resultado;
  }

  // 3.2 Método auxiliar para construir los botones de filtro
  Widget _buildFilterButton(String filtro) {
    final isSelected = _filtroSeleccionado == filtro;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filtroSeleccionado = filtro;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.teal,
        side: BorderSide(color: Colors.teal, width: isSelected ? 2 : 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        filtro,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  // 4. Pantalla principal - construye la UI con balance y lista de transacciones
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mi SmartWallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // 5. Cuerpo principal con FutureBuilder para cargar datos de BD
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbService.getTransaccionesFormateadas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transacciones = snapshot.data ?? [];
          final transaccionesFiltradas = _transaccionesFiltradas(transacciones);

          return Column(
            children: [
              // 5.1 Tarjeta con el balance total usando FutureBuilder
              FutureBuilder<double>(
                future: _dbService.calcularBalance(),
                builder: (context, balanceSnapshot) {
                  final balance = balanceSnapshot.data ?? 0.0;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Balance Actual',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '\$${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // 5.2 Sección de filtros mejorada
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_alt, color: Colors.teal),
                        const SizedBox(width: 10),
                        const Text(
                          'Filtrar Transacciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botones de filtro organizados en Wrap para mejor distribución
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterButton('Todas'),
                        _buildFilterButton('Más Recientes'),
                        _buildFilterButton('Ingresos'),
                        _buildFilterButton('Egresos'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 5.3 Título de la sección de transacciones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.teal),
                    const SizedBox(width: 10),
                    const Text(
                      'Transacciones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 5.4 Lista de transacciones filtradas
              Expanded(
                child: transaccionesFiltradas.isEmpty
                    ? const Center(
                        child: Text('No hay transacciones para este filtro'),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ListView.builder(
                          itemCount: transaccionesFiltradas.length,
                          itemBuilder: (context, index) {
                            final tx = transaccionesFiltradas[index];
                            // Determina si es ingreso (verde) o egreso (rojo)
                            final esIngreso = tx['tipo'] == 'Ingreso';
                            final color = esIngreso ? Colors.green : Colors.red;
                            final monto = tx['monto'] as double;
                            final fecha = tx['fecha'] as DateTime;
                            final categoria = tx['categoria'] as String;

                            return ListTile(
                              // Icono de la transacción con color según tipo
                              leading: Icon(
                                esIngreso
                                    ? Icons.add_circle
                                    : Icons.remove_circle,
                                color: color,
                              ),
                              // Titulo: nombre de la transacción
                              title: Text(tx['titulo']),
                              // Subtítulo: muestra categoría y fecha formateada
                              subtitle: Text(
                                '$categoria • ${_formatoFecha(fecha)}',
                              ),
                              // Monto: muestra el valor con signo y color
                              trailing: Text(
                                '${esIngreso ? '' : '-'}\$${monto.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      // 6. Botón flotante para agregar nueva transacción
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 6.1 Navega a la pantalla AddTransactionScreen
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );

          // 6.2 Actualizar UI después de agregar transacción
          if (mounted) {
            _actualizarUI();
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
