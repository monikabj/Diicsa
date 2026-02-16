import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'entrada_salida_herramienta_screen.dart';
import 'editar_herramienta_screen.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class DetalleHerramientaScreen extends StatefulWidget {
  final String docId;

  const DetalleHerramientaScreen({super.key, required this.docId});

  @override
  State<DetalleHerramientaScreen> createState() =>
      _DetalleHerramientaScreenState();
}

class _DetalleHerramientaScreenState
    extends State<DetalleHerramientaScreen> {
  final ImagePicker _picker = ImagePicker();
  bool cargandoImagen = false;

  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? imagen =
        await _picker.pickImage(source: source, imageQuality: 60);
    if (imagen == null) return;

    setState(() => cargandoImagen = true);

    final bytes = await imagen.readAsBytes();
    final base64Img = base64Encode(bytes);

    await FirebaseFirestore.instance
        .collection('herramientas')
        .doc(widget.docId)
        .update({
      'imagenesBase64': [base64Img],
    });

    setState(() => cargandoImagen = false);
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


  Future<void> _eliminarFoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Seguro que deseas eliminar la imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('herramientas')
          .doc(widget.docId)
          .update({
        'imagenesBase64': [],
      });
    }
  }


  Future<void> _eliminarHerramienta() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar herramienta'),
        content:
            const Text('¿Seguro que deseas eliminar esta herramienta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('herramientas')
          .doc(widget.docId)
          .delete();

      if (!mounted) return;
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de herramienta'),
        backgroundColor: azulDiicsa,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('herramientas')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;
          final imagenes = data['imagenesBase64'];

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
                    imagenes != null &&
                            imagenes is List &&
                            imagenes.isNotEmpty
                        ? Image.memory(
                            base64Decode(imagenes.first),
                            height: 180,
                            fit: BoxFit.contain,
                          )
                        : const Padding(
                            padding: EdgeInsets.all(32),
                            child: Icon(
                              Icons.handyman,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),


                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_camera),
                          onPressed: cargandoImagen
                              ? null
                              : _opcionesImagen,
                        ),
                        if (imagenes != null &&
                            imagenes is List &&
                            imagenes.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: _eliminarFoto,
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
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(data['descripcion']),
              const SizedBox(height: 8),
              Text('Marca: ${data['marca']}'),
              Text('Organizador: ${data['organizador']}'),
              Text('Sección: ${data['seccion']}'),
              const SizedBox(height: 16),
              Text(
                'Existencia: ${data['cantidadDisponible']}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 28),


              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulDiicsa,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Editar herramienta',
                  style:
                      TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditarHerramientaScreen(
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
                      icon:
                          const Icon(Icons.arrow_upward),
                      label:
                          const Text('Solicitar'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EntradaSalidaHerramientaScreen(
                              herramientaId:
                                  widget.docId,
                              tipo: 'entrega',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          const Icon(Icons.arrow_downward),
                      label:
                          const Text('Devolucion'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EntradaSalidaHerramientaScreen(
                              herramientaId:
                                  widget.docId,
                              tipo: 'recepcion',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              
              TextButton.icon(
                icon: const Icon(Icons.delete,
                    color: Colors.red),
                label: const Text(
                  'Eliminar herramienta',
                  style:
                      TextStyle(color: Colors.red),
                ),
                onPressed: _eliminarHerramienta,
              ),
            ],
          );
        },
      ),
    );
  }
}