import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/trabajador_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        //Cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        //No hay sesión
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // validar rol
        return const _RedirectByRole();
      },
    );
  }
}

class _RedirectByRole extends StatefulWidget {
  const _RedirectByRole();

  @override
  State<_RedirectByRole> createState() => _RedirectByRoleState();
}

class _RedirectByRoleState extends State<_RedirectByRole> {
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      return await _auth.obtenerUsuario(user.uid);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {

        //Cargando datos del usuario
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;

        //Error o usuario no encontrado
        if (data == null) {
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }

        final rol = data['rol'];
        final activo = data['activo'] ?? false;

        //Usuario desactivado
        if (!activo) {
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }

        // CONTROL DE ACCESO POR ROL
        if (rol == 'admin') {
          return const HomeScreen();
        }

        if (rol == 'trabajador') {
          return const TrabajadorHomeScreen();
        }

        
        FirebaseAuth.instance.signOut();
        return const LoginScreen();
      },
    );
  }
}