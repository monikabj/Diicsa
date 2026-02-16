import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class EntradaSalidaHerramientaScreen extends StatefulWidget {
  final String herramientaId;
  final String tipo; // 'entrega' | 'recepcion'

  const EntradaSalidaHerramientaScreen({
    super.key,
    required this.herramientaId,
    required this.tipo,
  });

  @override
  State<EntradaSalidaHerramientaScreen> createState() =>
      _EntradaSalidaHerramientaScreenState();
}

class _EntradaSalidaHerramientaScreenState
    extends State<EntradaSalidaHerramientaScreen> {

  final _cantidadCtrl = TextEditingController(text: '1');
  final _personaCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String estadoHerramienta = 'Buena';
  bool guardando = false;

  Future<void> _guardarMovimiento() async {
    if (_personaCtrl.text.trim().isEmpty) return;

    setState(() => guardando = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final usuarioData = userDoc.data() as Map<String, dynamic>;

    final usuarioEmail = user.email;
    final nombreUsuario = usuarioData['nombre'] ?? '';
    final rol = usuarioData['rol'] ?? '';

    final herramientaRef = FirebaseFirestore.instance
        .collection('herramientas')
        .doc(widget.herramientaId);

    final herramientaSnap = await herramientaRef.get();
    final herramienta = herramientaSnap.data()!;

    final codigoInterno = herramienta['codigoInterno'];
    final descripcion = herramienta['descripcion'] ?? '';

    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 1;
    int stockActual = herramienta['cantidadDisponible'];


    if (widget.tipo == 'entrega') {
      if (stockActual < cantidad) {
        setState(() => guardando = false);
        return;
      }
      stockActual -= cantidad;
    } else {
      if (estadoHerramienta != 'Extraviada') {
        stockActual += cantidad;
      }
    }

    final batch = FirebaseFirestore.instance.batch();


    batch.update(herramientaRef, {
      'cantidadDisponible': stockActual,
    });


    batch.set(
      FirebaseFirestore.instance
          .collection('movimientos_herramientas')
          .doc(),
      {
        'herramientaId': widget.herramientaId,
        'codigoInterno': codigoInterno,
        'descripcion': descripcion,
        'tipo': widget.tipo,
        'cantidad': cantidad,


        'personaResponsable': _personaCtrl.text.trim(),


        'usuarioEmail': usuarioEmail,
        'nombreUsuario': nombreUsuario,
        'rol': rol,

        'estado': estadoHerramienta,
        'observaciones': _obsCtrl.text.trim(),
        'existenciaActual': stockActual,
        'fecha': Timestamp.now(),
      },
    );

    await batch.commit();

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final esEntrega = widget.tipo == 'entrega';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esEntrega ? 'Entregar herramienta' : 'Recibir herramienta',
        ),
        backgroundColor: azulDiicsa,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            TextField(
              controller: _personaCtrl,
              decoration: InputDecoration(
                labelText:
                    esEntrega ? '¿Quién recibe?' : '¿Quién entrega?',
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: estadoHerramienta,
              decoration:
                  const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(value: 'Buena', child: Text('Buena')),
                DropdownMenuItem(value: 'Dañada', child: Text('Dañada')),
                DropdownMenuItem(
                    value: 'Extraviada', child: Text('Extraviada')),
              ],
              onChanged: (v) => setState(() => estadoHerramienta = v!),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _obsCtrl,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulDiicsa,
                  foregroundColor: Colors.white,
                ),
                onPressed: guardando ? null : _guardarMovimiento,
                child: guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar movimiento',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}