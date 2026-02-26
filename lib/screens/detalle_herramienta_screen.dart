import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'entrada_salida_herramienta_screen.dart';
import 'editar_herramienta_screen.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class DetalleHerramientaScreen extends StatefulWidget {
  final String docId;

  const DetalleHerramientaScreen({
    super.key,
    required this.docId,
  });

  @override
  State<DetalleHerramientaScreen> createState() =>
      _DetalleHerramientaScreenState();
}

class _DetalleHerramientaScreenState
    extends State<DetalleHerramientaScreen> {

  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();

  bool cargandoImagen = false;
  int paginaActual = 0;

  Future<void> _agregarImagen(ImageSource source) async {
    final XFile? imagen =
        await _picker.pickImage(source: source, imageQuality: 60);

    if (imagen == null) return;

    setState(() => cargandoImagen = true);

    final bytes = await imagen.readAsBytes();
    final base64Img = base64Encode(bytes);

    final docRef = FirebaseFirestore.instance
        .collection('herramientas')
        .doc(widget.docId);

    final snap = await docRef.get();
    final data = snap.data() as Map<String, dynamic>;

    List imagenes = List.from(data['imagenesBase64'] ?? []);

    if (imagenes.length >= 3) {
      setState(() => cargandoImagen = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 3 imágenes por herramienta'),
        ),
      );
      return;
    }

    imagenes.add(base64Img);

    await docRef.update({
      'imagenesBase64': imagenes,
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
                _agregarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _agregarImagen(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarImagen(int index, List imagenes) async {
    imagenes.removeAt(index);

    await FirebaseFirestore.instance
        .collection('herramientas')
        .doc(widget.docId)
        .update({
      'imagenesBase64': imagenes,
    });

    if (paginaActual >= imagenes.length && paginaActual > 0) {
      paginaActual--;
      _pageController.jumpToPage(paginaActual);
    }

    setState(() {});
  }

  Future<void> _eliminarHerramienta() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar herramienta'),
        content: const Text(
            '¿Seguro que deseas eliminar esta herramienta?'),
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
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
            return const Center(
                child: CircularProgressIndicator());
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final existencia = data['cantidadDisponible'] ?? 0;
          List imagenes = List.from(data['imagenesBase64'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ================= HEADER DASHBOARD =================
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
                      data['codigoInterno'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['descripcion'],
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= CARD EXISTENCIA =================
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.handyman,
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
                        'Herramientas disponibles',
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
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [

                      const SizedBox(height: 12),

                      if (imagenes.isNotEmpty)
                        Column(
                          children: [

                            SizedBox(
                              height: 280,
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
                                      height: 250,
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
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_a_photo),
                                  onPressed: cargandoImagen
                                      ? null
                                      : _opcionesImagen,
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _eliminarImagen(
                                          paginaActual, imagenes),
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
                                Icons.handyman,
                                size: 120,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              IconButton(
                                icon:
                                    const Icon(Icons.add_a_photo),
                                onPressed: _opcionesImagen,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= INFO CARD =================
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow('Marca', data['marca']),
                      _infoRow('Organizador', data['organizador']),
                      _infoRow('Sección', data['seccion']),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulDiicsa,
                  foregroundColor: Colors.white,
                  minimumSize:
                      const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Editar herramienta',
                  style: TextStyle(
                      fontWeight: FontWeight.bold),
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
                          const Text('Devolución'),
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

  Widget _infoRow(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}