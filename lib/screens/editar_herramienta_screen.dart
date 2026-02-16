import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class EditarHerramientaScreen extends StatefulWidget {
  final String docId;

  const EditarHerramientaScreen({super.key, required this.docId});

  @override
  State<EditarHerramientaScreen> createState() =>
      _EditarHerramientaScreenState();
}

class _EditarHerramientaScreenState
    extends State<EditarHerramientaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  String organizador = 'Organizador 1';
  String seccion = '';

  bool cargando = true;
  bool guardando = false;

  final List<String> organizadores =
      List.generate(9, (i) => 'Organizador ${i + 1}');

  @override
  void initState() {
    super.initState();
    _cargarHerramienta();
  }

  Future<void> _cargarHerramienta() async {
    final doc = await FirebaseFirestore.instance
        .collection('herramientas')
        .doc(widget.docId)
        .get();

    final data = doc.data()!;

    _codigoCtrl.text = data['codigoInterno'];
    _descCtrl.text = data['descripcion'];
    _marcaCtrl.text = data['marca'];
    _cantidadCtrl.text = data['cantidadDisponible'].toString();
    organizador = data['organizador'];
    seccion = data['seccion'];

    setState(() => cargando = false);
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => guardando = true);

    await FirebaseFirestore.instance
        .collection('herramientas')
        .doc(widget.docId)
        .update({
      'codigoInterno': _codigoCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'marca': _marcaCtrl.text.trim(),
      'cantidadDisponible': int.parse(_cantidadCtrl.text),
      'organizador': organizador,
      'seccion': seccion,
      'updatedAt': Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Herramienta actualizada')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar herramienta'),
        backgroundColor: azulDiicsa,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _codigoCtrl,
                decoration:
                    const InputDecoration(labelText: 'Código interno'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Descripción'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _marcaCtrl,
                decoration: const InputDecoration(labelText: 'Marca'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cantidadCtrl,
                decoration:
                    const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: organizador,
                decoration:
                    const InputDecoration(labelText: 'Organizador'),
                items: organizadores
                    .map(
                      (o) => DropdownMenuItem(
                        value: o,
                        child: Text(o),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => organizador = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: seccion,
                decoration:
                    const InputDecoration(labelText: 'Sección'),
                onChanged: (v) => seccion = v,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulDiicsa,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: guardando ? null : _guardarCambios,
                child: guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar cambios',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}