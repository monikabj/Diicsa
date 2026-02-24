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
  final PageController _pageController = PageController();

  bool cargandoImagen = false;
  int paginaActual = 0;

  // ================== SELECCIONAR IMAGEN ==================
  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? imagen =
        await _picker.pickImage(source: source, imageQuality: 60);
    if (imagen == null) return;

    setState(() => cargandoImagen = true);

    final bytes = await imagen.readAsBytes();
    final base64Image = base64Encode(bytes);

    final docRef = FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId);

    final snap = await docRef.get();
    final data = snap.data() as Map<String, dynamic>;

    List imagenes = List.from(data['imagenesBase64'] ?? []);

    if (imagenes.length >= 3) {
      setState(() => cargandoImagen = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 3 imágenes por producto'),
        ),
      );
      return;
    }

    imagenes.add(base64Image);

    await docRef.update({'imagenesBase64': imagenes});

    setState(() => cargandoImagen = false);
  }

  // ================== OPCIONES ==================
  void _opcionesImagen() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================== ELIMINAR IMAGEN ==================
  Future<void> _eliminarImagen(int index, List imagenes) async {
    imagenes.removeAt(index);

    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId)
        .update({'imagenesBase64': imagenes});

    if (paginaActual >= imagenes.length && paginaActual > 0) {
      paginaActual--;
      _pageController.jumpToPage(paginaActual);
    }

    setState(() {});
  }

  // ================== ELIMINAR PRODUCTO ==================
  Future<void> _eliminarProducto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          'Esta acción no se puede deshacer.\n¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(widget.docId)
          .delete();

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('productos')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text('Este producto ya fue eliminado'),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          List imagenes = List.from(data['imagenesBase64'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ================== IMÁGENES ==================
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    if (imagenes.isNotEmpty)
                      Column(
                        children: [

                          // ===== Imagen grande =====
                          SizedBox(
                            height: 300,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: imagenes.length,
                              onPageChanged: (index) {
                                setState(() => paginaActual = index);
                              },
                              itemBuilder: (_, index) {
                                return Center(
                                  child: Image.memory(
                                    base64Decode(imagenes[index]),
                                    height: 260,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '${paginaActual + 1} / ${imagenes.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 10),

                          // ===== Miniaturas =====
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: imagenes.length,
                              itemBuilder: (_, index) {
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.jumpToPage(index);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: paginaActual == index
                                            ? azulDiicsa
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.memory(
                                      base64Decode(imagenes[index]),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_a_photo),
                                onPressed:
                                    cargandoImagen ? null : _opcionesImagen,
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    _eliminarImagen(paginaActual, imagenes),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.image_not_supported,
                              size: 120,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            IconButton(
                              icon: const Icon(Icons.add_a_photo),
                              onPressed: _opcionesImagen,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                data['codigoInterno'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data['descripcion'],
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(
                'Existencia: ${data['cantidadDisponible']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
    

              const SizedBox(height: 32),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulDiicsa,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Editar producto'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarProductoScreen(
                        docId: widget.docId,
                      ),
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

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

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
}