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


  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? imagen =
        await _picker.pickImage(source: source, imageQuality: 60);
    if (imagen == null) return;

    setState(() => cargandoImagen = true);

    final bytes = await imagen.readAsBytes();
    final base64Image = base64Encode(bytes);

    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId)
        .update({'imagenBase64': base64Image});

    if (mounted) setState(() => cargandoImagen = false);
  }

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

  Future<void> _eliminarImagen() async {
    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId)
        .update({'imagenBase64': FieldValue.delete()});
  }


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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('productos')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Este producto ya fue eliminado',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;
          final imagen = data['imagenBase64'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    imagen != null
                        ? Image.memory(
                            base64Decode(imagen),
                            height: 180,
                            fit: BoxFit.contain,
                          )
                        : const Padding(
                            padding: EdgeInsets.all(32),
                            child: Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Cambiar imagen',
                          icon: const Icon(Icons.photo_camera),
                          onPressed: _opcionesImagen,
                        ),
                        if (imagen != null)
                          IconButton(
                            tooltip: 'Eliminar imagen',
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: _eliminarImagen,
                          ),
                      ],
                    ),
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
                icon:
                    const Icon(Icons.delete, color: Colors.red),
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
