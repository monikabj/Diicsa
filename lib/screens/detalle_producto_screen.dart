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

  /// Selecciona una imagen y la añade a Firestore
  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      setState(() => cargandoImagen = true);

      final XFile? imagen =
          await _picker.pickImage(source: source, imageQuality: 60);
      if (imagen == null) {
        setState(() => cargandoImagen = false);
        return;
      }

      final bytes = await imagen.readAsBytes();
      final base64Image = base64Encode(bytes);

      final docRef = FirebaseFirestore.instance
          .collection('productos')
          .doc(widget.docId);

      final snap = await docRef.get();

      if (!mounted) return;

      if (!snap.exists) {
        _mostrarError('El producto no existe');
        setState(() => cargandoImagen = false);
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      List<dynamic> imagenes = List.from(data['imagenesBase64'] ?? []);

      // Validar límite máximo
      if (imagenes.length >= 3) {
        _mostrarSnackBar('Máximo 3 imágenes permitidas', Colors.orange);
        setState(() => cargandoImagen = false);
        return;
      }

      // Añadir imagen
      imagenes.add(base64Image);

      await docRef.update({'imagenesBase64': imagenes});

      if (!mounted) return;
      _mostrarSnackBar('Imagen añadida correctamente', Colors.green);
      setState(() => cargandoImagen = false);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _mostrarError('Error Firebase: ${e.message}');
      setState(() => cargandoImagen = false);
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error al seleccionar imagen: $e');
      setState(() => cargandoImagen = false);
    }
  }

  /// Elimina una imagen específica - VERSIÓN SEGURA
  Future<void> _eliminarImagen(int index) async {
    try {
      // Validar índice ANTES de cualquier operación
      if (index < 0) {
        _mostrarError('Índice inválido');
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('productos')
          .doc(widget.docId);

      // Obtener datos actuales ANTES de eliminar
      final snap = await docRef.get();

      if (!snap.exists) {
        _mostrarError('El producto no existe');
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      List<dynamic> imagenes = List.from(data['imagenesBase64'] ?? []);

      // Validar que el índice existe en la lista actual
      if (index >= imagenes.length) {
        _mostrarError('La imagen no existe (índice fuera de rango)');
        return;
      }

      // Eliminar imagen
      imagenes.removeAt(index);

      // Actualizar en Firestore
      await docRef.update({'imagenesBase64': imagenes});

      if (!mounted) return;

      // Ajustar paginaActual después de eliminar
      if (paginaActual >= imagenes.length && paginaActual > 0) {
        setState(() => paginaActual--);
      } else {
        setState(() {});
      }

      _mostrarSnackBar('Imagen eliminada correctamente', Colors.green);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _mostrarError('Error Firebase: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error al eliminar imagen: $e');
    }
  }

  /// Elimina el producto completo
  Future<void> _eliminarProducto() async {
    // Confirmación
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este producto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(widget.docId)
          .delete();

      if (!mounted) return;
      _mostrarSnackBar('Producto eliminado', Colors.green);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _mostrarError('Error Firebase: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error al eliminar: $e');
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
          // Manejo de errores de conexión
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Validar que el documento existe
          if (!snapshot.data!.exists) {
            return const Center(
              child: Text('El producto no existe'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final existencia = data['cantidadDisponible'] ?? 0;
          List<dynamic> imagenes = List.from(data['imagenesBase64'] ?? []);

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
                      data['codigoInterno'] ?? '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['descripcion'] ?? '—',
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
                          size: 40, color: azulDiicsa),
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
                          child: _construirImagen(
                              imagenes, paginaActual),
                        )
                      else
                        Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image_not_supported,
                              size: 120, color: Colors.grey),
                        ),

                      const SizedBox(height: 16),

                      // MINIATURAS
                      if (imagenes.length > 1)
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imagenes.length,
                            itemBuilder: (context, index) {
                              final seleccionada = index == paginaActual;

                              return GestureDetector(
                                onTap: () {
                                  setState(() => paginaActual = index);
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
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
                                    child: _construirImagenMiniatura(
                                        imagenes, index),
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
                            onPressed: cargandoImagen
                                ? null
                                : () => _seleccionarImagen(
                                    ImageSource.gallery),
                          ),
                          const SizedBox(width: 20),
                          if (cargandoImagen)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: imagenes.isEmpty
                                  ? null
                                  : () =>
                                      _eliminarImagen(paginaActual),
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
                      _filaInfo(Icons.confirmation_number, 'Número de parte',
                          data['numeroParte'] ?? '—'),
                      _filaInfo(Icons.business, 'Marca',
                          data['marca'] ?? '—'),
                      _filaInfo(
                        Icons.location_on,
                        'Ubicación',
                        'Anaquel ${data['anaquel'] ?? '—'} · Sección ${data['seccion'] ?? '—'}',
                      ),
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

  /// Construye la imagen principal con manejo de errores
  Widget _construirImagen(List<dynamic> imagenes, int index) {
    try {
      if (index < 0 || index >= imagenes.length) {
        return Container(
          height: 260,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image_not_supported,
                size: 100, color: Colors.grey),
          ),
        );
      }

      return Image.memory(
        base64Decode(imagenes[index] as String),
        height: 260,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 260,
            color: Colors.red.shade100,
            child: const Icon(Icons.broken_image,
                size: 100, color: Colors.red),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 260,
        color: Colors.red.shade100,
        child: Center(
          child: Text('Error: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }
  }

  /// Construye la miniatura de imagen con manejo de errores
  Widget _construirImagenMiniatura(List<dynamic> imagenes, int index) {
    try {
      if (index < 0 || index >= imagenes.length) {
        return Container(
          width: 70,
          height: 70,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported,
              size: 30, color: Colors.grey),
        );
      }

      return Image.memory(
        base64Decode(imagenes[index] as String),
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 70,
            color: Colors.red.shade100,
            child: const Icon(Icons.broken_image,
                size: 30, color: Colors.red),
          );
        },
      );
    } catch (e) {
      return Container(
        width: 70,
        height: 70,
        color: Colors.red.shade100,
        child: const Icon(Icons.error, size: 30, color: Colors.red),
      );
    }
  }

  Widget _filaInfo(IconData icon, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: azulDiicsa),
          const SizedBox(width: 10),
          Expanded(child: Text(titulo)),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
