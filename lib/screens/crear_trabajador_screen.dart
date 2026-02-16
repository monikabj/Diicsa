import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CrearTrabajadorScreen extends StatefulWidget {
  const CrearTrabajadorScreen({super.key});

  @override
  State<CrearTrabajadorScreen> createState() =>
      _CrearTrabajadorScreenState();
}

class _CrearTrabajadorScreenState extends State<CrearTrabajadorScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool loading = false;
  bool _verPassword = false;

  static const Color azulDiicsa = Color(0xFF1F4E79);

  Future<void> _crearTrabajador() async {
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
      await _auth.crearTrabajador(
        nombre: nombre,
        email: email,
        password: password,
      );

      _mensaje('Trabajador creado correctamente');

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
        title: const Text('Crear Trabajador'),
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
                onPressed: loading ? null : _crearTrabajador,
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