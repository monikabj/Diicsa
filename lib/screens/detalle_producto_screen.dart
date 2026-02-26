import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'entrada_salida_screen.dart';
import 'editar_producto_screen.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class DetalleProductoScreen extends StatefulWidget {
  final String docId;

  const DetalleProductoScreen({super.key, required this.docId});

  @override
  State<DetalleProductoScreen> createState() =>
      _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  final ImagePicker _picker = ImagePicker();

  bool cargandoImagen = false;
  int paginaActual = 0;

  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? imagen =
        await _picker.pickImage(source: source, imageQuality: 60);
    if (imagen == null) return;

    final bytes = await imagen.readAsBytes();
    final base64Image = base64Encode(bytes);

    final docRef = FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId);

    final snap = await docRef.get();
    final data = snap.data() as Map<String, dynamic>;

    List imagenes = List.from(data['imagenesBase64'] ?? []);

    if (imagenes.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 imágenes')),
      );
      return;
    }

    imagenes.add(base64Image);
    await docRef.update({'imagenesBase64': imagenes});
  }

  Future<void> _eliminarImagen(int index, List imagenes) async {
    imagenes.removeAt(index);

    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId)
        .update({'imagenesBase64': imagenes});

    if (paginaActual >= imagenes.length && paginaActual > 0) {
      paginaActual--;
    }

    setState(() {});
  }

  Future<void> _eliminarProducto() async {
    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId)
        .delete();

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: azulDiicsa,
        title: const Text('Detalle del producto'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('productos')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final existencia = data['cantidadDisponible'] ?? 0;
          List imagenes = List.from(data['imagenesBase64'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ================= HEADER =================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: azulDiicsa,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['codigoInterno'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['descripcion'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= EXISTENCIA =================
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2,
                          size: 40,
                          color: azulDiicsa),
                      const SizedBox(height: 10),
                      Text(
                        '$existencia',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Existencia actual',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= IMÁGENES =================
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      // IMAGEN PRINCIPAL
                      if (imagenes.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(imagenes[paginaActual]),
                            height: 260,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        const Icon(Icons.image_not_supported, size: 120),

                      const SizedBox(height: 16),

                      // MINIATURAS
                      if (imagenes.length > 1)
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imagenes.length,
                            itemBuilder: (context, index) {
                              final seleccionada =
                                  index == paginaActual;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    paginaActual = index;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: seleccionada
                                          ? azulDiicsa
                                          : Colors.grey.shade300,
                                      width: seleccionada ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(imagenes[index]),
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 16),

                      // BOTONES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_a_photo),
                            onPressed: () =>
                                _seleccionarImagen(ImageSource.gallery),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: imagenes.isEmpty
                                ? null
                                : () => _eliminarImagen(
                                    paginaActual, imagenes),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= INFO =================
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _filaInfo(Icons.confirmation_number,
                          'Número de parte',
                          data['numeroParte'] ?? '—'),
                      _filaInfo(Icons.business, 'Marca',
                          data['marca'] ?? '—'),
                      _filaInfo(Icons.location_on, 'Ubicación',
                          'Anaquel ${data['anaquel'] ?? '—'} · Sección ${data['seccion'] ?? '—'}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulDiicsa,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Editar producto'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditarProductoScreen(docId: widget.docId),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Entrada'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntradaSalidaScreen(
                              productoId: widget.docId,
                              tipo: 'entrada',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.remove),
                      label: const Text('Salida'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntradaSalidaScreen(
                              productoId: widget.docId,
                              tipo: 'salida',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Eliminar producto',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: _eliminarProducto,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filaInfo(
      IconData icon, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: azulDiicsa),
          const SizedBox(width: 10),
          Expanded(child: Text(titulo)),
          Text(valor,
              style:
                  const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}