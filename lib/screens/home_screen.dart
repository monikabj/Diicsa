import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color azulDiicsa = Color(0xFF1F4E79);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: azulDiicsa,
        elevation: 0,
        title: Image.asset(
          'assets/images/logo-diicsa.png',
          height: 28,
        ),
      ),

      drawer: Drawer(
        backgroundColor: azulDiicsa,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: azulDiicsa),
              child: Center(
                child: Image.asset(
                  'assets/images/logo-diicsa.png',
                  height: 70,
                ),
              ),
            ),


            _drawerItem(
              context: context,
              icon: Icons.home,
              text: 'Inicio',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _drawerItem(
              context: context,
              icon: Icons.inventory_2,
              text: 'Inventario',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/inventario');
              },
            ),

            _drawerItem(
              context: context,
              icon: Icons.build,
              text: 'Herramientas',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/herramientas');
              },
            ),

            _drawerItem(
              context: context,
              icon: Icons.history,
              text: 'Historial de movimientos',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                    context, '/historial-movimientos');
              },
            ),

            _drawerItem(
  context: context,
  icon: Icons.build_circle,
  text: 'Historial herramientas',
  onTap: () {
    Navigator.pop(context);
    Navigator.pushNamed(
        context, '/historial-herramientas');
  },
),

            _drawerItem(
              context: context,
              icon: Icons.person_add,
              text: 'Crear Admin',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/crear-admin');
              },
            ),

            _drawerItem(
              context: context,
              icon: Icons.engineering,
              text: 'Crear Trabajador',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/crear-trabajador');
              },
            ),

            _drawerItem(
              context: context,
              icon: Icons.people,
              text: 'Gestionar usuarios',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/usuarios');
              },
            ),

            const Divider(color: Colors.white70),

            _drawerItem(
              context: context,
              icon: Icons.logout,
              text: 'Cerrar sesión',
              onTap: () async {
                Navigator.pop(context);
                await AuthService().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _titulo('Resumen de inventario'),
          const SizedBox(height: 12),
          _tarjetaStockBajo(),
        ],
      ),
    );
  }

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _tarjetaStockBajo() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('productos')
          .where('cantidadDisponible', isLessThanOrEqualTo: 5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Text('No hay productos con stock bajo');
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(
                  data['codigoInterno'],
                  style:
                      const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(data['descripcion']),
                trailing: Text(
                  data['cantidadDisponible'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
