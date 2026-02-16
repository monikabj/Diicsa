import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/pdf_services.dart';

class HistorialMovimientosScreen extends StatefulWidget {
  const HistorialMovimientosScreen({super.key});

  @override
  State<HistorialMovimientosScreen> createState() =>
      _HistorialMovimientosScreenState();
}

class _HistorialMovimientosScreenState
    extends State<HistorialMovimientosScreen> {

  static const Color azulDiicsa = Color(0xFF1F4E79);

  DateTime? fechaInicio;
  DateTime? fechaFin;


  Future<void> _seleccionarDia() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        fechaInicio = DateTime(picked.year, picked.month, picked.day);
        fechaFin =
            DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Future<void> _seleccionarMes() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      helpText: 'Selecciona cualquier día del mes',
    );

    if (picked != null) {
      setState(() {
        fechaInicio = DateTime(picked.year, picked.month, 1);
        fechaFin =
            DateTime(picked.year, picked.month + 1, 0, 23, 59, 59);
      });
    }
  }

  Stream<QuerySnapshot> _movimientosStream() {
    if (fechaInicio != null && fechaFin != null) {
      return FirebaseFirestore.instance
          .collection('movimientos')
          .where('fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio!))
          .where('fecha',
              isLessThanOrEqualTo: Timestamp.fromDate(fechaFin!))
          .orderBy('fecha', descending: true)
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('movimientos')
        .orderBy('fecha', descending: true)
        .snapshots();
  }


 void _exportarPDF() {
  PdfService.generarReporteMovimientos(
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Historial de movimientos'),
        backgroundColor: azulDiicsa,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 8,
                )
              ],
            ),
            child: Column(
              children: [

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Día'),
                        onPressed: _seleccionarDia,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: azulDiicsa,
                          side: const BorderSide(color: azulDiicsa),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: const Text('Mes'),
                        onPressed: _seleccionarMes,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: azulDiicsa,
                          side: const BorderSide(color: azulDiicsa),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar PDF'),
                        onPressed: _exportarPDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulDiicsa,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        child: const Text(
                          'Quitar filtro',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          setState(() {
                            fechaInicio = null;
                            fechaFin = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _movimientosStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No hay movimientos registrados'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final esEntrada = data['tipo'] == 'entrada';
                    final fecha =
                        (data['fecha'] as Timestamp).toDate();

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              esEntrada ? Colors.green : Colors.red,
                          child: Icon(
                            esEntrada
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${esEntrada ? 'Entrada' : 'Salida'} - ${data['codigoInterno']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Cantidad: ${data['cantidad']}'),
                            Text('Usuario: ${data['usuarioEmail']}'),
                            Text('Rol: ${data['rol']}'),
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}',
                            ),
                            if (data['observaciones'] != null &&
                                data['observaciones']
                                    .toString()
                                    .isNotEmpty)
                              Text(
                                  'Obs: ${data['observaciones']}'),
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
      ),
    );
  }
}
