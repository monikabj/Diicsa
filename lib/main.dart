import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'auth_gate.dart';
import 'screens/herramientas_screen.dart';
import 'screens/usuarios_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/agregar_producto_screen.dart';
import 'screens/entrada_salida_screen.dart';
import 'screens/historial_producto_screen.dart';
import 'screens/trabajador_home_screen.dart';
import 'screens/crear_admin_screen.dart';
import 'screens/crear_trabajador_screen.dart';
import 'screens/historial_movimientos.dart';
import 'screens/historial_movimientos_herramienta_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DIICSA',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F4E79),
          foregroundColor: Colors.white,
        ),
      ),

      // 🔐 CONTROL TOTAL DE SESIÓN
      home: const AuthGate(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(), // ADMIN
        '/inventario': (context) => const InventarioScreen(),
        '/agregar-producto': (context) => const AgregarProductoScreen(),
        '/trabajador': (context) => const TrabajadorHomeScreen(),
        '/crear-admin': (context) => const CrearAdminScreen(),
        '/crear-trabajador': (context) => const CrearTrabajadorScreen(),
        '/usuarios': (context) => const UsuariosScreen(),
        '/historial-movimientos': (context) => const HistorialMovimientosScreen(),
        '/herramientas': (context) => const HerramientasScreen(),
        '/historial-herramientas': (_) => const HistorialMovimientosHerramientasScreen(),


      },

      onGenerateRoute: (settings) {
        if (settings.name == '/entrada-salida') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => EntradaSalidaScreen(
              productoId: args['productoId'],
              tipo: args['tipo'],
            ),
          );
        }

        if (settings.name == '/historial') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => HistorialProductoScreen(
              productoId: args['productoId'],
            ),
          );
        }

        return null;
      },
    );
  }
}
