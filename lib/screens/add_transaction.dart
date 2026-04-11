import 'package:flutter/material.dart';
import '../services/db_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // 1. Controladores para el formulario y servicio de BD
  final _tituloController = TextEditingController();
  final _montoController = TextEditingController();
  final _categoriaController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  String _tipoTransaccion = 'Ingreso';
  String _categoriaSeleccionada = 'General';
  DateTime _fechaSeleccionada = DateTime.now();
  bool _isLoading = false;

  // 2. Lista de categorías dinámicas
  final List<String> categorias = ['General', 'Alimentos', 'Transporte'];

  // 3. Método para agregar nueva categoría
  void _agregarCategoria() {
    final categoria = _categoriaController.text.trim();
    if (categoria.isEmpty) return;

    if (!categorias.contains(categoria)) {
      setState(() {
        categorias.add(categoria);
        _categoriaSeleccionada = categoria;
      });
    }
    _categoriaController.clear();
  }

  // 4. Método para seleccionar fecha con DatePicker
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  // 5. Método para formatear la fecha como dd/mm/yyyy
  String _formatoFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  // 6. Método para guardar la transacción en la BD
  Future<void> _guardarTransaccion() async {
    final titulo = _tituloController.text.trim();
    final monto = double.tryParse(_montoController.text.replaceAll(',', '.'));

    // Validación: Verificar que el título no esté vacío y el monto sea válido
    if (titulo.isEmpty || monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un título y un monto válido')),
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Guardar en la base de datos - el monto se guarda con signo según el tipo
      final montoFinal = _tipoTransaccion == 'Ingreso'
          ? monto.abs()
          : -monto.abs();

      await _dbService.insertTransaccion(
        nombre: titulo,
        tipo: _tipoTransaccion,
        categoria: _categoriaSeleccionada,
        monto: montoFinal,
        fecha: _fechaSeleccionada,
      );

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción guardada exitosamente')),
        );

        // Volver a la pantalla anterior
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Nueva Transacción',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 7. Campo: Nombre de la transacción
            const Text(
              'Nombre de la Transacción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                hintText: 'Ej: Compra en supermercado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),

            // 8. Campo: Tipo de transacción (Ingreso/Egreso)
            const Text(
              'Tipo de Transacción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _tipoTransaccion,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Ingreso', child: Text('Ingreso')),
                DropdownMenuItem(value: 'Egreso', child: Text('Egreso')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tipoTransaccion = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // 9. Campo: Seleccionar categoría existente
            const Text(
              'Categoría',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _categoriaSeleccionada,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: categorias
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _categoriaSeleccionada = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // 10. Campo: Agregar nueva categoría dinámicamente
            const Text(
              'Agregar Nueva Categoría',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoriaController,
                    decoration: InputDecoration(
                      hintText: 'Nueva categoría',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.add),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _agregarCategoria();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 11. Campo: Monto de la transacción
            const Text('Monto', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _montoController,
              decoration: InputDecoration(
                hintText: 'Ej: 150.50',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 20),

            // 12. Campo: Seleccionar fecha
            const Text(
              'Fecha de la Transacción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.teal),
                    const SizedBox(width: 10),
                    Text(
                      'Fecha: ${_formatoFecha(_fechaSeleccionada)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 13. Botón para guardar la transacción
            ElevatedButton(
              onPressed: _isLoading ? null : _guardarTransaccion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Guardar Transacción',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 10),

            // 14. Botón para cancelar (volver atrás sin guardar)
            OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.teal),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 15. Limpiar controladores al salir de la pantalla
    _tituloController.dispose();
    _montoController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }
}
