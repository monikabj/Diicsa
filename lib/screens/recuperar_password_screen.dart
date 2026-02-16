import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState
    extends State<RecuperarPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool loading = false;

  static const Color azulDiicsa = Color(0xFF1F4E79);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulDiicsa,
      appBar: AppBar(
        backgroundColor: azulDiicsa,
        elevation: 0,
        title: const Text('Recuperar contraseña'),
      ),
      body: Center(
        child: SizedBox(
          width: 380,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_reset,
                    size: 64,
                    color: azulDiicsa,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Ingresa tu correo y te enviaremos un enlace para restablecerla.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: loading ? null : _enviarCorreo,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Enviar enlace',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enviarCorreo() async {
    if (_emailCtrl.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      await _auth.recuperarPassword(
        _emailCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Correo enviado. Revisa tu bandeja de entrada o spam.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}