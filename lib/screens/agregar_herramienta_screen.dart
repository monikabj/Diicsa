import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color azulDiicsa = Color(0xFF1F4E79);

class AgregarHerramientaScreen extends StatefulWidget {
  const AgregarHerramientaScreen({super.key});

  @override
  State<AgregarHerramientaScreen> createState() =>
      _AgregarHerramientaScreenState();
}

class _AgregarHerramientaScreenState
    extends State<AgregarHerramientaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _numeroParteCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _seccionCtrl = TextEditingController();

  String organizador = 'Organizador 1';

  final List<String> organizadores =
      List.generate(9, (i) => 'Organizador ${i + 1}');

  final Map<String, String> seccionPorOrganizador = {
    'Organizador 1': 'Z-Z-I',
    'Organizador 2': 'Z-Z-J',
    'Organizador 3': 'Z-Z-K',
    'Organizador 4': 'Z-Z-L',
    'Organizador 5': 'Z-Z-M',
    'Organizador 6': 'Z-Z-N',
    'Organizador 7': 'Z-Z-Ñ',
    'Organizador 8': 'Z-Z-O',
    'Organizador 9': 'Z-Z-P',
  };

  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _seccionCtrl.text = seccionPorOrganizador[organizador]!;
  }

  Future<void> _guardarHerramienta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => guardando = true);

    await FirebaseFirestore.instance.collection('herramientas').add({
      'codigoInterno': _codigoCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'marca': _marcaCtrl.text.trim(),
      'numeroParte': _numeroParteCtrl.text.trim(),
      'cantidadDisponible': int.parse(_cantidadCtrl.text),
      'organizador': organizador,
      'seccion': _seccionCtrl.text,
      'segmento': 'Herramienta',
      'imagenesBase64': [],
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar herramienta'),
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
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _numeroParteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Número de parte'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(
                    labelText: 'Cantidad disponible'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

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
                onChanged: (v) {
                  setState(() {
                    organizador = v!;
                    _seccionCtrl.text =
                        seccionPorOrganizador[organizador]!;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _seccionCtrl,
                enabled: false,
                decoration:
                    const InputDecoration(labelText: 'Sección'),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulDiicsa,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: guardando ? null : _guardarHerramienta,
                  child: guardando
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Guardar herramienta',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}