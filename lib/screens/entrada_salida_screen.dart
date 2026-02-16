import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class EntradaSalidaScreen extends StatefulWidget {
  final String productoId;
  final String tipo; // entrada | salida

  const EntradaSalidaScreen({
    super.key,
    required this.productoId,
    required this.tipo,
  });

  @override
  State<EntradaSalidaScreen> createState() =>
      _EntradaSalidaScreenState();
}

class _EntradaSalidaScreenState
    extends State<EntradaSalidaScreen> {
  final _cantidadCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  bool guardando = false;

  Future<void> _guardarMovimiento() async {
    if (_cantidadCtrl.text.isEmpty) return;

    setState(() => guardando = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final rol = userDoc['rol'];

    final productoRef = FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.productoId);

    final productoSnap = await productoRef.get();
    final producto = productoSnap.data()!;

    final cantidad = int.parse(_cantidadCtrl.text);

    final nuevaCantidad = widget.tipo == 'entrada'
        ? producto['cantidadDisponible'] + cantidad
        : producto['cantidadDisponible'] - cantidad;

    await productoRef.update({
      'cantidadDisponible' : nuevaCantidad,
    });


    await FirebaseFirestore.instance
        .collection('movimientos')
        .add({
      'productoId': widget.productoId,
      'codigoInterno': producto['codigoInterno'],
      'descripcion': producto['descripcion'],
      'tipo': widget.tipo,
      'cantidad': cantidad,
      'usuarioEmail': user.email,
      'rol': rol,
      'observaciones': _obsCtrl.text.trim(),
      'fecha': Timestamp.now(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipo == 'entrada'
              ? 'Registrar entrada'
              : 'Registrar salida',
        ),
        backgroundColor: azulDiicsa,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
              ),
            ),
            const SizedBox(height: 16),


            TextField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                hintText:
                    'Ej. Producto dañado, pedido urgente, ajuste de inventario',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulDiicsa,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed:
                  guardando ? null : _guardarMovimiento,
              child: guardando
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      'Guardar movimiento',
                      style: TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
