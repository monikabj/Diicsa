import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialProductoScreen extends StatefulWidget {
  final String productoId;

  const HistorialProductoScreen({
    super.key,
    required this.productoId,
  });

  @override
  State<HistorialProductoScreen> createState() =>
      _HistorialProductoScreenState();
}

class _HistorialProductoScreenState extends State<HistorialProductoScreen> {
  DateTime? fechaInicio;
  int filtroSeleccionado = 0;

  final List<String> filtros = ['Hoy', '7 días', '30 días', 'Todos'];

  Stream<QuerySnapshot<Map<String, dynamic>>> _historialStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('movimientos')
        .where('productoId', isEqualTo: widget.productoId)
        .orderBy('fecha', descending: true);

    if (fechaInicio != null) {
      query = query.where(
        'fecha',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio!),
      );
    }

    return query.snapshots();
  }

  void _aplicarFiltro(int index) {
    final now = DateTime.now();

    setState(() {
      filtroSeleccionado = index;
      switch (index) {
        case 0:
          fechaInicio = DateTime(now.year, now.month, now.day);
          break;
        case 1:
          fechaInicio = now.subtract(const Duration(days: 7));
          break;
        case 2:
          fechaInicio = now.subtract(const Duration(days: 30));
          break;
        default:
          fechaInicio = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de movimientos')),
      body: Column(
        children: [
          _filtrosFecha(),
          const Divider(height: 1),
          Expanded(child: _contenidoHistorial()),
        ],
      ),
    );
  }

  Widget _filtrosFecha() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        children: List.generate(filtros.length, (index) {
          return ChoiceChip(
            label: Text(filtros[index]),
            selected: filtroSeleccionado == index,
            onSelected: (_) => _aplicarFiltro(index),
            selectedColor: const Color(0xFF1F4E79),
            labelStyle: TextStyle(
              color: filtroSeleccionado == index
                  ? Colors.white
                  : Colors.black,
            ),
          );
        }),
      ),
    );
  }

  Widget _contenidoHistorial() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _historialStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar historial'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          children: [
            _totalesHistorial(docs),
            const Divider(),
            Expanded(child: _listaHistorial(docs)),
          ],
        );
      },
    );
  }

  Widget _totalesHistorial(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int totalEntradas = 0;
    int totalSalidas = 0;

    for (final doc in docs) {
      final data = doc.data();
      final tipo = data['tipo'];
      final cantidad = data['cantidad'] ?? 0;

      if (tipo == 'entrada') {
        totalEntradas += cantidad as int;
      } else if (tipo == 'salida') {
        totalSalidas += cantidad as int;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _cardTotal(
              titulo: 'Entradas',
              valor: totalEntradas,
              color: Colors.green,
              icono: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _cardTotal(
              titulo: 'Salidas',
              valor: totalSalidas,
              color: Colors.red,
              icono: Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTotal({
    required String titulo,
    required int valor,
    required Color color,
    required IconData icono,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icono, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  valor.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaHistorial(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return const Center(child: Text('Sin movimientos registrados'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data();

        final tipo = data['tipo'] ?? 'entrada';
        final cantidad = data['cantidad'] ?? 0;
        final fecha =
            (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();

        final esEntrada = tipo == 'entrada';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(
              esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
              color: esEntrada ? Colors.green : Colors.red,
            ),
            title: Text(
              esEntrada ? 'ENTRADA' : 'SALIDA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
                Text(DateFormat('dd/MM/yyyy HH:mm').format(fecha)),
            trailing: Text(
              esEntrada ? '+$cantidad' : '-$cantidad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: esEntrada ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}
