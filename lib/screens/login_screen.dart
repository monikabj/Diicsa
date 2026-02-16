import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'recuperar_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool loading = false;
  bool _verPassword = false; // 👁️ ojito

  static const Color azulDiicsa = Color(0xFF1F4E79);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulDiicsa,
      body: Center(
        child: SizedBox(
          width: 380,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo-diicsa.png',
                    height: 60,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: !_verPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _verPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _verPassword = !_verPassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RecuperarPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: azulDiicsa),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                      onPressed: loading ? null : _login,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Iniciar sesión',
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

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _mostrarError('Ingresa correo y contraseña');
      return;
    }

    setState(() => loading = true);

    try {
      final user = await _auth.login(email, password);

      if (user == null) {
        throw Exception();
      }

      final data = await _auth.obtenerUsuario(user.uid);

      if (data['bloqueado'] == true) {
        _mostrarError(
          'Cuenta bloqueada por intentos fallidos.\nContacta al administrador.',
        );
        return;
      }

      if (data['activo'] != true) {
        _mostrarError(
          'Usuario inactivo. Contacta al administrador.',
        );
        return;
      }

      await _auth.reiniciarIntentos(user.uid);

      final rol = data['rol'];

      if (!mounted) return;

      if (rol == 'admin') {
        Navigator.pushReplacementNamed(context, '/');
      } else if (rol == 'trabajador') {
        Navigator.pushReplacementNamed(context, '/trabajador');
      } else {
        _mostrarError('Rol no válido');
      }
    } on FirebaseAuthException {
      await _registrarIntentoFallido(email);
      _mostrarError('Correo o contraseña incorrectos');
    } catch (_) {
      _mostrarError('Correo o contraseña incorrectos');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _registrarIntentoFallido(String email) async {
    final query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await _auth.registrarIntentoFallido(query.docs.first.id);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}