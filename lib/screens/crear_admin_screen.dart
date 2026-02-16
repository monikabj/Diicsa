import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class CrearAdminScreen extends StatefulWidget {
  const CrearAdminScreen({super.key});

  @override
  State<CrearAdminScreen> createState() => _CrearAdminScreenState();
}

class _CrearAdminScreenState extends State<CrearAdminScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool loading = false;
  bool _verPassword = false;

  static const Color azulDiicsa = Color(0xFF1F4E79);

  @override
  void initState() {
    super.initState();
    _validarAdmin();
  }

  Future<void> _validarAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (doc.data()?['rol'] != 'admin') {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _crearAdmin() async {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _mensaje('Completa todos los campos');
      return;
    }

    if (!_auth.passwordSegura(password)) {
      _mensaje(
        'La contraseña debe tener:\n'
        '• 8 caracteres mínimo\n'
        '• Una mayúscula\n'
        '• Un número\n'
        '• Un símbolo',
      );
      return;
    }

    setState(() => loading = true);

    try {
      await _auth.crearAdmin(
        nombre: nombre,
        email: email,
        password: password,
      );

      _mensaje('Administrador creado correctamente');

      _nombreCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
    } catch (e) {
      _mensaje(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Administrador'),
        backgroundColor: azulDiicsa,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordCtrl,
              obscureText: !_verPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                helperText:
                    'Mín. 8 caracteres, mayúscula, número y símbolo',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _verPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _verPassword = !_verPassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulDiicsa,
                  foregroundColor: Colors.white,
                ),
                onPressed: loading ? null : _crearAdmin,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Crear',
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