import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import '../services/firestore_service.dart';

class AgregarProductoScreen extends StatefulWidget {
  const AgregarProductoScreen({super.key});

  @override
  State<AgregarProductoScreen> createState() =>
      _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _service = FirestoreService();

  int _anaquel = 1;
  String _seccion = 'A';
  String _segmento = 'Control';

  final _codigoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _numeroParteCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  final List<String> segmentos = ['Control', 'Neumático'];

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alta de Producto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: _anaquel,
                decoration: const InputDecoration(labelText: 'Anaquel'),
                items: List.generate(
                  5,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Anaquel ${i + 1}'),
                  ),
                ),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _anaquel = v;
                    _seccion = seccionesPorAnaquel[_anaquel]!.first;
                  });
                },
              ),

              DropdownButtonFormField<String>(
                value: _seccion,
                decoration: const InputDecoration(labelText: 'Sección'),
                items: seccionesPorAnaquel[_anaquel]!
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _seccion = v!),
              ),

              DropdownButtonFormField<String>(
                value: _segmento,
                decoration: const InputDecoration(labelText: 'Segmento'),
                items: segmentos
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _segmento = v!),
              ),

              const SizedBox(height: 16),

              _input(_codigoCtrl, 'Código interno'),
              _input(_descripcionCtrl, 'Descripción'),
              _input(_numeroParteCtrl, 'Número de parte'),
              _input(_marcaCtrl, 'Marca'),
              _input(_cantidadCtrl, 'Cantidad inicial',
                  tipo: TextInputType.number),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _guardarProducto,
                child: const Text('Guardar producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final cantidad = int.parse(_cantidadCtrl.text);

    final producto = ProductoModel(
      id: '',
      anaquel: _anaquel,
      seccion: _seccion,
      segmento: _segmento,
      codigoInterno: _codigoCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      numeroParte: _numeroParteCtrl.text.trim(),
      marca: _marcaCtrl.text.trim(),
      cantidadInicial: cantidad,
      cantidadDisponible: cantidad,
      cantidadTotal: cantidad,
      cantidadSalidas: 0,
      createdAt: Timestamp.now(),
    );

    await _service.agregarProducto(producto);

    if (!mounted) return;
    _mensaje('Producto agregado correctamente');
    Navigator.pop(context);
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _input(
    TextEditingController ctrl,
    String label, {
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: tipo,
        validator: (v) =>
            v == null || v.isEmpty ? 'Campo obligatorio' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
