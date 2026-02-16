import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class EditarProductoScreen extends StatefulWidget {
  final String docId;
  const EditarProductoScreen({super.key, required this.docId});

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _segmentoCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  int anaquel = 1;
  String seccion = '';

  bool cargando = true;
  bool guardando = false;

  final Map<int, List<String>> seccionesPorAnaquel = {
    1: [
      ...List.generate(26, (i) => String.fromCharCode(65 + i)),
      'Ñ',
      'Z-A',
      'Z-B',
      'Z-C',
    ],
    2: ['Z-D', 'Z-E', 'Z-F', 'Z-G', 'Z-H', 'Z-I'],
    3: [
      'Z-J','Z-K','Z-L','Z-M','Z-N','Z-Ñ','Z-O',
      'Z-P','Z-Q','Z-R','Z-S','Z-T','Z-U',
    ],
    4: ['Z-V'],
    5: [
      'Z-W','Z-X','Z-Y','Z-Z','Z-Z-A','Z-Z-B',
      'Z-Z-C','Z-Z-D','Z-Z-E','Z-Z-F','Z-Z-G','Z-Z-H',
    ],
  };

  @override
  void initState() {
    super.initState();
    _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    final doc = await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId)
        .get();

    final data = doc.data()!;
    _codigoCtrl.text = data['codigoInterno'];
    _descCtrl.text = data['descripcion'];
    _marcaCtrl.text = data['marca'] ?? '';
    _segmentoCtrl.text = data['segmento'] ?? '';
    _cantidadCtrl.text = data['cantidadDisponible'].toString();
    anaquel = data['anaquel'];
    seccion = data['seccion'];

    setState(() => cargando = false);
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => guardando = true);

    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.docId)
        .update({
      'codigoInterno': _codigoCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'marca': _marcaCtrl.text.trim(),
      'segmento': _segmentoCtrl.text.trim(),
      'cantidadDisponible': int.parse(_cantidadCtrl.text),
      'anaquel': anaquel,
      'seccion': seccion,
      'updatedAt': Timestamp.now(),
    });

    if (!mounted) return;
    _mensaje('Producto actualizado');
    Navigator.pop(context);
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final secciones = seccionesPorAnaquel[anaquel]!;

    if (!secciones.contains(seccion)) {
      seccion = secciones.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar producto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _input(_codigoCtrl, 'Código interno'),
              _input(_descCtrl, 'Descripción'),
              _input(_marcaCtrl, 'Marca'),
              _input(_segmentoCtrl, 'Segmento'),
              _input(_cantidadCtrl, 'Cantidad',
                  tipo: TextInputType.number),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: anaquel,
                decoration: const InputDecoration(labelText: 'Anaquel'),
                items: List.generate(
                  5,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Anaquel ${i + 1}'),
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    anaquel = v!;
                    seccion = seccionesPorAnaquel[anaquel]!.first;
                  });
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: seccion,
                decoration: const InputDecoration(labelText: 'Sección'),
                items: secciones
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => seccion = v!),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulDiicsa,
                  foregroundColor: Colors.white,
                ),
                onPressed: guardando ? null : _guardarCambios,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String l, {
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: tipo,
        validator: (v) =>
            v == null || v.isEmpty ? 'Campo obligatorio' : null,
        decoration: InputDecoration(labelText: l),
      ),
    );
  }
}
