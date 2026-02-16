import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class HistorialMovimientosHerramientasScreen extends StatefulWidget {
  const HistorialMovimientosHerramientasScreen({super.key});

  @override
  State<HistorialMovimientosHerramientasScreen> createState() =>
      _HistorialMovimientosHerramientasScreenState();
}

class _HistorialMovimientosHerramientasScreenState
    extends State<HistorialMovimientosHerramientasScreen> {

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
        fechaInicio =
            DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        fechaFin =
            DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Stream<QuerySnapshot> _movimientosStream() {
    Query query = FirebaseFirestore.instance
        .collection('movimientos_herramientas')
        .orderBy('fecha', descending: true);

    if (fechaInicio != null && fechaFin != null) {
      query = query
          .where('fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio!))
          .where('fecha',
              isLessThanOrEqualTo: Timestamp.fromDate(fechaFin!));
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial herramientas'),
        backgroundColor: azulDiicsa,
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulDiicsa,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Filtrar por día'),
              onPressed: _seleccionarDia,
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

                    final tipo = data['tipo'] ?? '';
                    final esEntrega = tipo == 'entrega';

                    final fecha =
                        (data['fecha'] as Timestamp).toDate();

                    return Card(
                      elevation: 4,
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [
                                Icon(
                                  esEntrega
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: esEntrega
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  esEntrega
                                      ? 'ENTREGA'
                                      : 'RECEPCIÓN',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 16,
                                    color: esEntrega
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text(
                              'Código: ${data['codigoInterno']}',
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold),
                            ),

                            Text(
                                'Descripción: ${data['descripcion'] ?? '—'}'),

                            const SizedBox(height: 6),

                            Text(
                                'Cantidad: ${data['cantidad']}'),

                            Text(
                                'Estado: ${data['estado'] ?? '—'}'),

                            const SizedBox(height: 8),

                            Text(
                              'Responsable: ${data['personaResponsable'] ?? '—'}',
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600),
                            ),

                            Text(
                                'Registrado por: ${data['nombreUsuario'] ?? '—'}'),

                            Text(
                                'Correo admin: ${data['usuarioEmail'] ?? '—'}'),

                            const SizedBox(height: 6),

                            Text(
                              'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} '
                              '${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Existencia actual: ${data['existenciaActual'] ?? 0}',
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