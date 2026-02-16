import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'agregar_herramienta_screen.dart';
import 'detalle_herramienta_screen.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class HerramientasScreen extends StatefulWidget {
  const HerramientasScreen({super.key});

  @override
  State<HerramientasScreen> createState() =>
      _HerramientasScreenState();
}

class _HerramientasScreenState extends State<HerramientasScreen> {
  String textoBusqueda = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Herramientas'),
        backgroundColor: azulDiicsa,
      ),

      // -------- FAB (+) --------
      floatingActionButton: FloatingActionButton(
        backgroundColor: azulDiicsa,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AgregarHerramientaScreen(),
            ),
          );
        },
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar herramienta',
              ),
              onChanged: (v) {
                setState(
                  () => textoBusqueda = v.trim().toLowerCase(),
                );
              },
            ),
          ),

          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('herramientas')
                  .orderBy('codigoInterno')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final texto = (
                    '${data['codigoInterno']} '
                    '${data['descripcion']} '
                    '${data['marca']} '
                    '${data['seccion']}'
                  ).toLowerCase();

                  return texto.contains(textoBusqueda);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No hay herramientas'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final imagenes = data['imagenesBase64'];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: imagenes != null &&
                                imagenes is List &&
                                imagenes.isNotEmpty
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(imagenes.first),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.handyman,
                                size: 32,
                                color: azulDiicsa,
                              ),
                        title: Text(
                          data['codigoInterno'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(data['descripcion']),
                            Text(
                              'Marca: ${data['marca']}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Organizador: ${data['organizador']}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          data['cantidadDisponible']
                              .toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetalleHerramientaScreen(
                                docId: docs[i].id,
                              ),
                            ),
                          );
                        },
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
